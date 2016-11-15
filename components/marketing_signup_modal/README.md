# Marketing Signup Modal

Adds a marketing popover to certain pages.

![](https://cloud.githubusercontent.com/assets/1022172/20309384/bd42951c-ab15-11e6-97e7-dcc7fda5d1a3.jpg)

## Usage

This uses config variables to determine where it's applied. Use `heroku config:set` to configure a campaign. Leaving `MARKETING_SIGNUP_MODAL_PATHS` empty will effectively turn it off.

Examples:

````
MARKETING_SIGNUP_MODAL_PATHS=/miami-beach,/feature/miami*
MARKETING_SIGNUP_MODAL_COPY=Sign up for early access
MARKETING_SIGNUP_MODAL_IMG=http://placekitten.com/200/200
````

If this expirment results in a worthwhile amount of collector acquistion then eventually the idea is we will replace this config data with a tool we give Marketing to manage themselves.

## Implementation

This is implemented globally in our layout component by checking against the config variables added to sharify.
