option limrow=100;

set air/A,B,C/;
set ts/1*17/;
set fleet/f1*f2/;
alias(i,j,air);
alias(ts1, ts2, ts);
set nodes(air, ts);
alias(n1, n2, nodes);

* skyarcs is basically the flight connections, i.e which airports are connected for this airlines.
set skyarcs(air, ts, air, ts) /
(A.1).(B.3),
(B.5).(C.7),
(C.9).(A.11)
/;

set groundarcs(air, ts, air, ts);
groundarcs(i, ts1, j, ts2) = yes$(sameAs(i, j) and ord(ts2) = ord(ts1) + 1);
groundarcs(i, '17', j, '1') = yes$(sameAs(i, j));
display groundarcs;

* Itineraries give the demand and fare. This is basically useful for connecting flights.
* The example here is such that there is a connecting flight through airport B. it3 gives this itinerary. The start is A and final destination is C.
set itinerary /i1*i4/;
set itarcs(itinerary, air, ts, air, ts)/
i1.(A.1).(B.3),
i2.(B.5).(C.7),
i3.(A.1).(B.3),
i3.(B.5).(C.7),
i4.(C.9).(A.11)
/;


parameter demand(itinerary)/i1 75, i2 150, i3 75, i4 50/;
parameter fare(itinerary) /i1 200, i2 225, i3 300, i4 200/;
parameter cap(fleet)/f1 100, f2 200/;
parameter num(fleet) /f1 1, f2 1/;

* Operating costs to fly between airports.
parameter opcos(fleet,air,air)/f1.A.B 10, f1.B.A 10, f1.B.C 20, f1.C.B 20, f1.C.A 15
f2.A.B 20, f2.B.C 39.5, f2.B.A 20, f2.C.B 39.5, f2.C.A 30
/;

* f is used to determine which fleet should be assigned to which flight
binary variable f(fleet, air, ts, air, ts);
* groundFlights gives the number of flights at the ground
positive variable groundFlights(fleet, air, ts, air, ts);
* costs parameter is the cost for assigning fleet to the flight
parameter costs(fleet, air, ts, air, ts);
costs(fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2) = 1000*opcos(fleet, i, j);

free variable obj;
alias(it1, it2, itinerary);

* t gives the number of people flying in each itinerary.
positive variable t(it1, i, ts1, j, ts2);
* k is used to make sure that the people assigned to an itinerary are preserved.
* This means that if 30 people are assigned to fly in it3( A-C ) from A-B, exactly 30 must also fly from B-C since it3 has the start as A and end as C.
positive variable k(itinerary);

equations objective, fleetAssignEq, groundFlightsEq(fleet, ts1), flowEq, itineraryUBoundEq, itineraryCapacityEq, preserveItineraryEq;

* The objective function maximizes the total attainable profit
objective..
obj =e= sum(itinerary, fare(itinerary)*k(itinerary)) - sum((fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2)*costs(fleet, i, ts1, j, ts2));

* This equation ensures we assign only one kind of fleet to any given flight
fleetAssignEq(i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
sum(fleet, f(fleet, i, ts1, j, ts2)) =e= 1;

* This equation ensures we are within the number of available fleets.
* For each fleet, time slot, the total of the sum of all groundflights and the sum of all assignments to flights must be less than the available number.
groundFlightsEq(fleet, ts1)..
sum((i, j, ts2)$groundarcs(i, ts1, j, ts2), groundFlights(fleet, i, ts1, j, ts2)) + sum((i, j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2)) =l= num(fleet);

* This equation is for the flow balance. For each type of fleet, the total number of flights on the ground plust the incoming flights is equal to the total number of flights on the ground in the next time slot plus the total outgoing flights.
flowEq(fleet, i, ts1)..
sum(ts$groundarcs(i, ts, i, ts1), groundFlights(fleet, i, ts, i, ts1)) + sum((j, ts2)$skyarcs(j, ts2, i, ts1), f(fleet, j, ts2, i, ts1)) =e= sum(ts$groundarcs(i, ts1, i, ts), groundFlights(fleet, i, ts1, i, ts)) + sum((j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2));

* The number of people assigned to each itinerary must be less than the demand.
itineraryUBoundEq(itinerary, i, ts1, j, ts2)$itarcs(itinerary, i, ts1, j, ts2)..
t(itinerary, i, ts1, j, ts2) =l= demand(itinerary);

* The total number of all people (from different itineraries) assigned to a flight must be less than the fleet capacity assigned to this flight.
itineraryCapacityEq(i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
sum(itinerary$itarcs(itinerary, i, ts1, j, ts2), t(itinerary, i, ts1, j, ts2)) =l= sum(fleet, f(fleet, i, ts1, j, ts2)*cap(fleet));

* If passengers were given to an itinerary then they must be flown entirely to the end. Cannot drop midwaaay....
preserveItineraryEq(itinerary, i, ts1, j, ts2)$itarcs(itinerary, i, ts1, j, ts2)..
t(itinerary, i, ts1, j, ts2) =e= k(itinerary);

model final /all/;
solve final using mip max obj;
display f.l, t.l;
display k.l;