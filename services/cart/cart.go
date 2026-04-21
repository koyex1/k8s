func main() {
  http.HandleFunc("/cart", func(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Added to cart")
  })
  http.ListenAndServe(":8080", nil)
}