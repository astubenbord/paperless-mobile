enum ViewType {
  grid,
  list;

  ViewType toggle() {
    return this == grid ? list : grid;
  }
}
