set air/A,B,C/;
set ts/1*17/;
set fleet/f1*f3/;
alias(i,j,air);
alias(ts1, ts2, ts);
set nodes(air, ts);
alias(n1, n2, nodes);
set skyarcs(air, ts, air, ts) /
(A.7).(B.9),
(A.9).(B.11),
(A.13).(B.15),
(B.1).(A.3),
(B.8).(A.10),
(B.13).(A.15),
(A.9).(C.15),
(A.11).(C.17),
(C.1).(A.7),
(C.4).(A.10)/;

set groundarcs(air, ts, air, ts);
groundarcs(i, ts1, j, ts2) = yes$(sameAs(i, j) and ord(ts2) = ord(ts1) + 1);
groundarcs(i, '17', j, '1') = yes$(sameAs(i, j));
display groundarcs;

$ontext
set flights/C1*C10/;
parameter dem(flights)/C1 250,C2 250,C3 100,C4 150,C5 300,C6 150,C7 150,C8 200,C9 200,C10 150/;
parameter fare(flights)/C1 150,C2 150,C3 150,C4 150,C5 150,C6 150,C7 400,C8 400,C9 400,C10 400/;
parameter cap(fleet)/f1 120,f2 150,f3 250/;
parameter opcos(fleet,flights)/f1.C1*C3 10,f2.C1*C3 12,f3.C1*C3 15,
f1.C4*C6 10,f2.C4*C6 12,f3.C4*C6 15,
f1.C7*C8 15,f2.C7*C8 17,f3.C7*C8 20,
f1.C9*C10 15,f2.C9*C10 17,f3.C9*C10 20/;
$offtext

parameter dem(i, ts1, j, ts2) /
(A.7.B.9) 250,
(A.9.B.11) 250,
(A.13.B.15) 100,
(B.1.A.3) 150,
(B.8.A.10) 300,
(B.13.A.15) 150,
(A.9.C.15) 150,
(A.11.C.17) 200, 
(C.1.A.7) 200,
(C.4.A.10) 150
/;

parameter fare(i, ts1, j, ts2)/
(A.7.B.9) 150,
(A.9.B.11) 150,
(A.13.B.15) 150,
(B.1.A.3) 150,
(B.8.A.10) 150,
(B.13.A.15) 150,
(A.9.C.15) 400,
(A.11.C.17) 400, 
(C.1.A.7) 400,
(C.4.A.10) 400
/;

parameter cap(fleet)/f1 120,f2 150,f3 250/;
parameter num(fleet) /f1 1, f2 2, f3 2/;

parameter opcos(fleet,air,air)/f1.A.B 10,f1.B.A 10,f1.A.C 15,f1.C.A 15,
f2.A.B 12,f2.B.A 12,f2.A.C 17,f2.C.A 17,
f3.A.B 15,f3.B.A 15,f3.A.C 20,f3.C.A 20/;

binary variable f(fleet, air, ts, air, ts);
positive variable groundFlights(fleet, air, ts, air, ts);
parameter costs(fleet, air, ts, air, ts);
costs(fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2) = fare(i, ts1, j, ts2)*min(dem(i, ts1, j, ts2), cap(fleet)) - opcos(fleet, i, j);
display costs;
*variable cost(fleet, air, ts, air, ts), min_value(fleet, air, ts, air, ts);
free variable obj;

equations objective, fleetAssignEq, groundFlightsEq, flowEq;
$ontext
minValue_eq1(fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
min_value(fleet, i, ts1, j, ts2) =l= dem(i, ts1, j, ts2);

minValue_eq2(fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
min_value(fleet, i, ts1, j, ts2) =l= cap(fleet);

assignCostEq(fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
cost(fleet, i, ts1, j, ts2) =e= fare(i, ts1, j, ts2)*min_value(fleet, i, ts1, j, ts2) - opcos(fleet, i, j)*1000;
$offtext

* The objective function maximizes the total attainable profit
objective..
obj =e= sum((fleet, i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2)*costs(fleet, i, ts1, j, ts2));

* This equation ensures we assign only one kind of fleet to any given flight
fleetAssignEq(i, ts1, j, ts2)$skyarcs(i, ts1, j, ts2)..
sum(fleet, f(fleet, i, ts1, j, ts2)) =e= 1;

* This equation ensures we are within the number of available fleets.
* For each fleet, time slot, the total of the sum of all groundflights and the sum of all assignments to flights must be less than the available number.
groundFlightsEq(fleet, ts1)..
sum((i, j, ts2)$groundarcs(i, ts1, j, ts2), groundFlights(fleet, i, ts1, j, ts2)) + sum((i, j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2)) =l= num(fleet);

* This equation is for the flow balance. For each type of fleet, the total number of flights on the ground plust the incoming flights is equal to the total number of flights on the ground in the next time slot plus the total outgoing flights.
flowEq(fleet, i, ts1)..
sum(ts$groundarcs(i, ts, i, ts1), groundFlights(fleet, i, ts, i, ts1)) + sum((j, ts2)$skyarcs(j, ts2, i, ts1), f(fleet, j, ts2, i, ts1))=e= sum(ts$groundarcs(i, ts1, i, ts), groundFlights(fleet, i, ts1, i, ts)) + sum((j, ts2)$skyarcs(i, ts1, j, ts2), f(fleet, i, ts1, j, ts2));

model final /all/;
solve final using mip max obj;
display f.l;
display groundFlights.l;