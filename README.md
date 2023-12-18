# bash-trans-info
This is an **unofficial** Bash library for Trans Info - the online service for real-time bus schedule that is active in some Bulgarian cities, for example, [Dobrich](https://traffic.dobrich.bg/).

This project utilizes the same RESTful API used by the front end of the original web service, but it is not affiliated with the authors of the platform in any way.

I wrote it primarily for hobbyists who want to incorporate the data into their projects (like IoT stuff) in an accessible form.

# Configuration

The library is configured to be used with the data for Dobrich by default.
Use the Developer Tools of your browser to check where the ASTI API is hosted for the Trans Info of your city. It is usually on a sub-domain and the port is always 8443, like:

* https://asti.dobrich.bg:8443
* https://gtsz.asti.eurogps.eu:8443/

Edit the endpoint in the **curl** parameters on the first lines of the script.

## Functions

Look at the source code for all the functions, but these are the primary ones used to retrieve usable info:

* **stopsFromLineId** - for a supplied line number as an argument, return a list of bus stops where the line is expected to arrive, with their name and ETA.
* **linesFromStopId** - for a supplied stop ID as an rgument, return a list of lines that pass by this stop, with the line's route name and ETA on this stop.
* **stopNameToStopId** - get a stop ID *(like 41547)* from stop name *(like "Шуменски университет")*.

## Dependencies

* jq
* curl
* awk

## Why Bash though?

Why not? It works.
