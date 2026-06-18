# Infrastructure for Yandex Cloud Managed Service for Kubernetes cluster
#
# Set the configuration of Managed Service for Kubernetes cluster

locals {
  k8s-cluster-name      = "k8s-cluster"          # Set a name for the cluster. It must be unique within the cloud.
  zone_a_v4_cidr_blocks = "10.1.0.0/16"          # Set the CIDR block for subnet in the ru-central1-a availability zone.
  alb_v4_cidr_blocks    = "10.2.0.0/24"          # CIDR for the dedicated (NAT-free) ALB subnet. Must not overlap subnet-a.
  cluster_ipv4_cidr     = "10.112.0.0/16"        # Set IP range for allocating pod addresses.
  service_ipv4_cidr     = "10.96.0.0/16"         # Set IP range for allocating service addresses.
  folder_id             = "<your-folder-id>"     # Set your cloud folder ID (yc resource-manager folder list).
  k8s_version           = "1.34"                 # Set the Kubernetes version.
  sa_name               = "k8s-sa"               # Cluster (control plane) service account name.
  node_sa_name          = "k8s-node-sa"          # Node group service account name (least privilege).
  platform_id           = "standard-v1"

  # CIDRs allowed to reach the Kubernetes API (443/6443) and SSH (22) on nodes.
  # TODO: replace 0.0.0.0/0 with your admin / CI ranges to lock this down.
  allowed_admin_cidrs = ["0.0.0.0/0"]

  # Roles granted to the cluster (control plane) service account.
  cluster_roles = [
    "alb.editor",
    "certificate-manager.certificates.downloader",
    "certificate-manager.editor",
    "compute.viewer",
    "k8s.viewer",
    "smart-web-security.editor",
    "logging.writer",
    "load-balancer.admin",
    "vpc.publicAdmin",
    "k8s.tunnelClusters.agent",
    "k8s.clusters.agent",
  ]

  # Minimal roles granted to the node group service account.
  node_roles = [
    "container-registry.images.puller",
  ]
}

resource "yandex_vpc_network" "k8s-network" {
  description = "Network for the Managed Service for Kubernetes cluster"
  name        = "k8s-network"
}

resource "yandex_vpc_subnet" "subnet-a" {
  description    = "Subnet in ru-central1-a availability zone"
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = [local.zone_a_v4_cidr_blocks]
  route_table_id = yandex_vpc_route_table.k8s-egress.id
}

# Dedicated subnet for the GWIN-managed L7 Application Load Balancer.
#
# It deliberately has NO route_table_id: a 0.0.0.0/0 -> NAT/egress-gateway
# default route in a subnet disables public-IP ingress for resources in it
# (documented YC routing behaviour). The ALB's data-plane nodes hold the public
# ALB IP, so allocating the ALB in subnet-a (which routes default egress through
# the NAT gateway for the private nodes) silently breaks the load balancer: the
# public IP stops answering and health checks never reach the targets.
#
# Keeping the ALB here (no default route) and the private nodes in subnet-a (NAT
# route) lets both work: the ALB reaches the node targets over internal VPC
# routing, while the nodes still get internet egress via the NAT gateway. GWIN is
# pointed at this subnet via the GatewayPolicy in the helm/gwin chart.
resource "yandex_vpc_subnet" "subnet-alb" {
  description    = "Dedicated subnet for the GWIN ALB. No NAT default route on purpose (see comment)."
  name           = "subnet-alb"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = [local.alb_v4_cidr_blocks]
}

# Egress-only NAT gateway so nodes reach the internet (image pulls, ACME, deSEC)
# without each node needing its own public IP.
resource "yandex_vpc_gateway" "nat" {
  name = "k8s-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "k8s-egress" {
  description = "Route default egress through the NAT gateway"
  name        = "k8s-egress-rt"
  network_id  = yandex_vpc_network.k8s-network.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_security_group" "k8s-cluster-nodegroup-traffic" {
  description = "The group rules allow service traffic for the cluster and node groups. Apply the rules to the cluster and the node groups."
  name        = "k8s-cluster-nodegroup-traffic"
  network_id  = yandex_vpc_network.k8s-network.id
  ingress {
    description       = "Rule for health checks of the network load balancer."
    from_port         = 0
    to_port           = 65535
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }
  ingress {
    description       = "Rule for incoming service traffic between the master and the nodes."
    from_port         = 0
    to_port           = 65535
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }
  ingress {
    description    = "Rule for health checks of nodes using ICMP requests from subnets within Yandex Cloud."
    protocol       = "ICMP"
    v4_cidr_blocks = [local.zone_a_v4_cidr_blocks]
  }
  ingress {
    # The GWIN ALB lives in subnet-alb (a different subnet than the nodes, see
    # yandex_vpc_subnet.subnet-alb). It forwards data-plane traffic to the node
    # NodePorts and runs the nodecheck health probes (NodePort 30501) from its
    # OWN subnet IPs. The loadbalancer_healthchecks predefined target does NOT
    # cover that source, so without this rule the hypervisor drops the ALB's
    # traffic and every backend stays UNHEALTHY (failed_active_hc).
    description    = "Allow the GWIN ALB (subnet-alb) to reach node NodePorts and the nodecheck port."
    from_port      = 0
    to_port        = 65535
    protocol       = "TCP"
    v4_cidr_blocks = [local.alb_v4_cidr_blocks]
  }
  egress {
    description       = "Rule for outgoing service traffic between the master and the nodes."
    from_port         = 0
    to_port           = 65535
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }
}

resource "yandex_vpc_security_group" "k8s-nodegroup-traffic" {
  description = "The group rules allow service traffic for the node groups. Apply the rules to the node groups."
  name        = "k8s-nodegroup-traffic"
  network_id  = yandex_vpc_network.k8s-network.id
  ingress {
    description    = "Rule for incoming traffic that allows traffic transfer between pods and services."
    from_port      = 0
    to_port        = 65535
    protocol       = "ANY"
    v4_cidr_blocks = [local.cluster_ipv4_cidr, local.service_ipv4_cidr]
  }
  egress {
    description    = "Rule for outgoing traffic that allows node group nodes to connect to external resources."
    from_port      = 0
    to_port        = 65535
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# PHASE-OUT: kept defined (but no longer attached to the node group) so the
# nodes can roll and drop their NIC references first. Delete this block in a
# second apply once the new nodes are up — see git history / the deploy notes.
resource "yandex_vpc_security_group" "k8s-services-access" {
  name        = "k8s-services-access"
  description = "DEPRECATED: NodePort access from the Internet. Pending removal once nodes roll."
  network_id  = yandex_vpc_network.k8s-network.id
  ingress {
    description    = "The rule allows incoming traffic in order to connect to Kubernetes services."
    from_port      = 30000
    to_port        = 32767
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# PHASE-OUT: same as above — remove in the second apply after nodes roll.
resource "yandex_vpc_security_group" "k8s-ssh-access" {
  description = "DEPRECATED: SSH to nodes. Pending removal once nodes roll."
  name        = "k8s-ssh-access"
  network_id  = yandex_vpc_network.k8s-network.id
  ingress {
    description    = "Rule for incoming traffic that allows connection to nodes via SSH."
    port           = 22
    protocol       = "TCP"
    v4_cidr_blocks = local.allowed_admin_cidrs
  }
}

resource "yandex_vpc_security_group" "k8s-cluster-traffic" {
  description = "The group rules allow traffic for the cluster. Apply the rules to the cluster."
  name        = "k8s-cluster-traffic"
  network_id  = yandex_vpc_network.k8s-network.id
  ingress {
    description    = "Rule for incoming traffic that allows access to the Kubernetes API (port 443)."
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = local.allowed_admin_cidrs
  }
  ingress {
    description    = "Rule for incoming traffic that allows access to the Kubernetes API (port 6443)."
    port           = 6443
    protocol       = "TCP"
    v4_cidr_blocks = local.allowed_admin_cidrs
  }
  egress {
    description    = "Rule for outgoing traffic that allows traffic transfer between the master and metric-server pods."
    port           = 4443
    protocol       = "TCP"
    v4_cidr_blocks = [local.cluster_ipv4_cidr]
  }
}

resource "yandex_iam_service_account" "k8s-sa" {
  name = local.sa_name
}

resource "yandex_iam_service_account" "k8s-node-sa" {
  name = local.node_sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "cluster_sa_roles" {
  for_each = toset(local.cluster_roles)

  folder_id = local.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "node_sa_roles" {
  for_each = toset(local.node_roles)

  folder_id = local.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.k8s-node-sa.id}"
}

# Managed Service for Kubernetes cluster
resource "yandex_kubernetes_cluster" "k8s-cluster" {
  description        = "Managed Service for Kubernetes cluster"
  name               = local.k8s-cluster-name
  network_id         = yandex_vpc_network.k8s-network.id
  cluster_ipv4_range = local.cluster_ipv4_cidr
  service_ipv4_range = local.service_ipv4_cidr

  master {
    version = local.k8s_version
    master_location {
      zone      = yandex_vpc_subnet.subnet-a.zone
      subnet_id = yandex_vpc_subnet.subnet-a.id
    }

    public_ip = true

    security_group_ids = [
      yandex_vpc_security_group.k8s-cluster-nodegroup-traffic.id,
      yandex_vpc_security_group.k8s-cluster-traffic.id
    ]

  }
  service_account_id      = yandex_iam_service_account.k8s-sa.id      # Cluster service account ID
  node_service_account_id = yandex_iam_service_account.k8s-node-sa.id # Node group service account ID
  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_sa_roles,
    yandex_resourcemanager_folder_iam_member.node_sa_roles
  ]
}

resource "yandex_kubernetes_node_group" "k8s-node-group" {
  description = "Node group for Managed Service for Kubernetes cluster"
  name        = "k8s-node-group"
  cluster_id  = yandex_kubernetes_cluster.k8s-cluster.id
  version     = local.k8s_version

  scale_policy {
    fixed_scale {
      size = 2 # Number of hosts
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  instance_template {
    platform_id = local.platform_id

    network_interface {
      # No per-node public IP: egress goes through the NAT gateway, ingress
      # arrives via the ALB (GWIN). Nodes keep only private addresses.
      nat        = false
      subnet_ids = [yandex_vpc_subnet.subnet-a.id]
      security_group_ids = [
        yandex_vpc_security_group.k8s-cluster-nodegroup-traffic.id,
        yandex_vpc_security_group.k8s-nodegroup-traffic.id,
      ]
    }

    scheduling_policy {
      preemptible = true
    }

    resources {
      memory = 4 # RAM quantity in GB
      cores  = 2 # Number of CPU cores
    }

    boot_disk {
      type = "network-hdd"
      size = 32 # Disk size in GB
    }
  }
}