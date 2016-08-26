module.exports = """
  me {
    id
    bidder_positions(artwork_id: $id) {
      is_winning
    }
  }
"""