var data = undefined

const pokedex = {
  *cargar(_self) {
    fetch('https://pokeapi.co/api/v2/pokemon/ditto')
      .then((res) => res.json())
      .then(pokemon => data = pokemon)
  },


  *ditto(_self) {
    if (!data) return yield* this.reify('No hay información')
    return yield* this.reify(data['name'])
  },
}

export { pokedex }