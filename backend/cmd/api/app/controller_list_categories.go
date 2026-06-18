package app

import (
	"encoding/json"
	"net/http"
)

func (i *Instance) ListCategoriesController(w http.ResponseWriter, r *http.Request) {
	type category struct {
		ID          int64  `json:"id"`
		Name        string `json:"name"`
		Description string `json:"description"`
	}

	categories := []category{
		{ID: 1, Name: "Raw", Description: "For true connoisseurs"},
		{ID: 2, Name: "Al dente", Description: "In the best traditions of Italian cuisine"},
		{ID: 3, Name: "Boiled", Description: "Timeless classic"},
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(categories)
}
