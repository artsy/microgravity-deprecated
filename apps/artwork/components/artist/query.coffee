module.exports = """
  artists {
    id
    name
    counts {
      artworks(format: "0,0")
      for_sale_artworks
    }
    href
    carousel {
      images {
        resized(height:200) {
          factor
          width
          height
          url
        }
        id
        title
        url
      }
    }
    bio
    biography: blurb(format: HTML)
    articles {
      title
      href
      author {
        name
      }
      image: thumbnail_image {
        thumb: cropped(width: 100, height: 100) {
          width
          height
          url
        }
      }
    }
    exhibition_history: shows {
      kind
      year: start_at(format: "YYYY")
      name
      href
      images {
        url
      }
      partner {
        ... on ExternalPartner {
          name
        }
        ... on Partner {
          name
        }
      }
      location {
        city
      }
    }
  }

"""
