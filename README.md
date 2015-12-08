# unladen
Pure Swift Web Server

Apple invented the Swift programming language for iOS and OSX apps, and it's been well-received by the developer community. But you need a Mac running OSX to use Swift. THEN, on Friday, Apple open-sourced Swift, and the developer community's first reaction was "now we can make servers in Swift and run them in the Cloud," because the Cloud runs Linux. Apple even released a Linux version of the Swift compiler. I thought it might be fun to benchmark a few Swift web servers on Linux, and compare them to other languages' web servers.

But as of this writing, you can't fire up Swift in Heroku, and installing Swift on Linux is a lot more daunting than just summoning apt-get, and although there are several projects that claim to be Swift web servers, I couldn't get a single one to serve up "Hello world". Most wouldn't even compile with the latest Swift v2. At least the prematurely-named "Perfect" ran, but I couldn't for the life of me get it to output "Hello world". Maybe they already had the domain name and figured why not.

So, with the hubris of any developer-at-heart, I made my own from scratch today. It's called "unladen" and available in GitHub here. If you're familiar with the API of Express.js, the popular node.js library, it should look familiar:

Run in Xcode (or even on Linux I suppose), and point your browser to 127.0.0.1:1999/foo?a=b and you'll see:

      you requested foo(["a": "b"]) 

Which is kind of neat. But what about performance? Apple claims Swift is "lightning-fast", although independent measurements show mixed results. None of that matters when my ham-fisted coding can make anything slow, and web servers are not bound by CPU but rather I/O , so language performance matters less than server architecture.

Back to my original goal of benchmarking a server, I used wbox to torture my newborn server on OSX with 100 simultaneous simulated clients, and compared it against node.js version 4.2.3. Ideally, one should not run the load tester and the target server on the same machine, but, throwing scientific rigor to the wind, here are my preliminary results:

+ unladen: time (ms) min/avg/max = 0/1.25/3
+ node.js: time (ms) min/avg/max = 1/2.50/4

Actually, I ran both several times, and results varied, but those seemed representative. The dear reader might conclude that Swift shows promise as a server language, or perhaps instead that my contrived experiment predictably reports favorable results. Regardless, there is now a working Swift web server, at least until Swift v3.
