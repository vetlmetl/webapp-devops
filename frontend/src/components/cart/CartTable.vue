<template>
  <table class="table table-hover align-middle">
    <thead>
      <tr>
        <th scope="col">Name</th>
        <th scope="col" style="width: 10%">Quantity</th>
        <th scope="col">Price</th>
        <th scope="col">Total</th>
        <th scope="col"></th>
      </tr>
    </thead>
    <tbody>
      <CartTableRow
        v-for="(cartItem, idx) in $store.getters.cartAsArray"
        :key="idx"
        :cartItem="cartItem"
      />
      <tr v-if="!$store.getters.cartAsArray.length">
        <td colspan="5" class="text-center">Cart is empty, <router-link to="/catalog">pick some dumplings in the catalog</router-link></td>
      </tr>
    </tbody>
  </table>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import CartTableRow from '@/components/cart/CartTableRow.vue';

export default defineComponent({
  name: 'Cart',
  components: {
    CartTableRow
  }
})
</script>
