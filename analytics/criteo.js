//
// Criteo tracking for auctions product feed and artworks product feed.
//

window.criteo_q = window.criteo_q || []
var pathSplit = location.pathname.split("/")
var userEmail = function() {
  return sd.CURRENT_USER ? [sd.CURRENT_USER.email] : [];
}()
if (pathSplit[1] === "auctions") {
  // Auctions events
  window.criteo_q.push(
    { event: "setAccount", account: sd.CRITEO_AUCTIONS_ACCOUNT_NUMBER },
    { event: "setSiteType", type: "m" },
    { event: "viewHome" }
  )
} else if (pathSplit[1] === "auction") {
  if (!pathSplit[3]) {
    window.criteo_q.push(
      { event: "setAccount", account: sd.CRITEO_AUCTIONS_ACCOUNT_NUMBER },
      { event: "setSiteType", type: "m" },
      { event: "viewList", item: sd.ARTWORKS.map(function(a) { return a._id }) }
    )
  } else if (pathSplit[3] === "bid") {
    analyticsHooks.on("confirm:bid", function(bidderPosition) {
      price = bidderPosition.get("max_bid_amount_cents") ? bidderPosition.get("max_bid_amount_cents") / 100 : null;
      window.criteo_q.push(
        { event: "setAccount", account: sd.CRITEO_AUCTIONS_ACCOUNT_NUMBER },
        { event: "setSiteType", type: "m" },
        {
          event: "trackTransaction",
          id: bidderPosition.get("bidder").id,
          item: [
            {
              id: bidderPosition.get("sale_artwork").artwork.id,
              price: price,
              quantity: 1
            }
          ]
        }
      )
    });
  }
} else if (pathSplit[1] === "artwork" && !pathSplit[3]) {
  // Auctions event
  window.criteo_q.push(
    { event: "setAccount", account: sd.CRITEO_AUCTIONS_ACCOUNT_NUMBER },
    { event: "setSiteType", type: "m" },
    { event: "viewItem", item: sd.AUCTION && sd.AUCTION.artwork_id }
  )
  // Artworks events
  window.criteo_q.push(
    { event: "setAccount", account: sd.CRITEO_ARTWORKS_ACCOUNT_NUMBER },
    { event: "setSiteType", type: "m" },
    { event: "setEmail", email: userEmail },
    { event: "viewItem", item: sd.ARTWORK._id }
  )
  analyticsHooks.on("inquiry_questionnaire:modal:opened", function(data) {
    window.criteo_q.push(
      { event: "setAccount", account: sd.CRITEO_ARTWORKS_ACCOUNT_NUMBER },
      { event: "setSiteType", type: "m" },
      { event: "setEmail", email: userEmail },
      {
        event: "viewBasket",
        item: [
          {
            id: sd.ARTWORK._id,
            price: sd.ARTWORK.price,
            quantity: 1
          }
        ]
      }
    )
  })
  analyticsHooks.on("inquiry:sync", function(data) {
    window.criteo_q.push(
      { event: "setAccount", account: sd.CRITEO_ARTWORKS_ACCOUNT_NUMBER },
      { event: "setSiteType", type: "m" },
      { event: "setEmail", email: userEmail },
      {
        event: "trackTransaction",
        item: [
          {
            id: sd.ARTWORK._id,
            price: sd.ARTWORK.price,
            quantity: 1
          }
        ]
      }
    )
  })
} else {
  // Artworks events
  if (pathSplit[1] === "collect") {
    window.criteo_q.push(
      { event: "setAccount", account: sd.CRITEO_ARTWORKS_ACCOUNT_NUMBER },
      { event: "setSiteType", type: "m" },
      { event: "setEmail", email: userEmail },
      { event: "viewHome" }
    )
  } else if (pathSplit[1] === "artist" && !pathSplit[3]) {
    window.criteo_q.push(
      { event: "setAccount", account: sd.CRITEO_ARTWORKS_ACCOUNT_NUMBER },
      { event: "setSiteType", type: "m" },
      { event: "setEmail", email: userEmail },
      { event: "viewList", item: _.pluck(_.filter(sd.ARTWORKS, (a) => a.forsale), '_id') }
    )
  }
}
