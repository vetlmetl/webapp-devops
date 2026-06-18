package dependencies

import (
	"gitlab.praktikum-services.ru/Stasyan/momo-store/internal/store/dumplings"
	"gitlab.praktikum-services.ru/Stasyan/momo-store/internal/store/dumplings/fake"
)

// NewFakeDumplingsStore returns new fake store for app
func NewFakeDumplingsStore() (dumplings.Store, error) {
	packs := []dumplings.Product{
		{
			ID:          1,
			Name:        "Pelmeni",
			Description: "With beef",
			Price:       5.00,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932687/repos/momos/8dee5a92281746aa887d6f19cf9fdcc7.jpg",
		},
		{
			ID:          2,
			Name:        "Khinkali",
			Description: "With pork",
			Price:       3.50,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932687/repos/momos/50b583271fa0409fb3d8ffc5872e99bb.jpg",
		},
		{
			ID:          3,
			Name:        "Manti",
			Description: "With young beef",
			Price:       2.75,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/8b50f76f514a4ccaaacdcb832a1b3a2f.jpg",
		},
		{
			ID:          4,
			Name:        "Buuz",
			Description: "With veal and onion",
			Price:       4.00,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/788c073d83c14b3fa00675306dfb32b5.jpg",
		},
		{
			ID:          5,
			Name:        "Jiaozi",
			Description: "With beef and pork",
			Price:       7.25,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/32cc88a33c3243a6a8838c034878c564.jpg",
		},
		{
			ID:          6,
			Name:        "Gyoza",
			Description: "With soy meat",
			Price:       3.50,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/7685ad7e9e634a58a4c29120ac5a5ee1.jpg",
		},
		{
			ID:          7,
			Name:        "Dim sum",
			Description: "With duck",
			Price:       2.65,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/4bdaeab0ee1842dc888d87d4a435afdd.jpg",
		},
		{
			ID:          8,
			Name:        "Momo",
			Description: "With lamb",
			Price:       5.00,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/f64dcea998e34278a0006e0a2b104710.jpg",
		},
		{
			ID:          9,
			Name:        "Wontons",
			Description: "With shrimp",
			Price:       4.10,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932687/repos/momos/8dee5a92281746aa887d6f19cf9fdcc7.jpg",
		},
		{
			ID:          10,
			Name:        "Baozi",
			Description: "With cabbage",
			Price:       4.20,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932687/repos/momos/50b583271fa0409fb3d8ffc5872e99bb.jpg",
		},
		{
			ID:          11,
			Name:        "Kundyumy",
			Description: "With mushrooms",
			Price:       5.45,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/8b50f76f514a4ccaaacdcb832a1b3a2f.jpg",
		},
		{
			ID:          12,
			Name:        "Kurze",
			Description: "With crab",
			Price:       3.25,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/788c073d83c14b3fa00675306dfb32b5.jpg",
		},
		{
			ID:          13,
			Name:        "Boraki",
			Description: "With beef and lamb",
			Price:       4.00,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/7685ad7e9e634a58a4c29120ac5a5ee1.jpg",
		},
		{
			ID:          14,
			Name:        "Ravioli",
			Description: "With ricotta",
			Price:       2.90,
			Image:       "https://res.cloudinary.com/sugrobov/image/upload/v1651932686/repos/momos/4bdaeab0ee1842dc888d87d4a435afdd.jpg",
		},
	}

	store := fake.NewStore()
	store.SetAvailablePacks(packs...)

	return store, nil
}
