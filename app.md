rollup import images includes hashes
https://github.com/sveltejs/sapper-template/issues/229

Wiring up the router could be vey clever
For the router go through all the files import the element and transform the path to a pattern
render the emelent to some file content and then create a routes js file that allows you to look up a route and pass a parameter
and errors if the route didn't exist.

Let's js render because with the service worker that should be instantaneous.


hash returns manifest that's looked up by service worker


Needs to assume logged in for installed app

Just preload the next conversation and all inbound pieces
