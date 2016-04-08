//************TimeTree************
//********************************
//CREATE HOURS
WITH range(0,23) as HOURS 
FOREACH (hour in HOURS | CREATE (:Hour {id:hour}));

//CREATE minutes
MATCH (h:Hour) WITH range(0,59) as MINUTES, h
FOREACH (mm in MINUTES | CREATE (:Minute {id:mm})<-[:HAS]-(h));

//CREATE SECONDS
MATCH (h:Hour)-[:HAS]->(mm: Minute) WITH h, mm, range(0,59) as SECONDS
FOREACH (ss in SECONDS | CREATE (:Second {id:ss})<-[:DIVIDED]-(mm));


CREATE INDEX ON :Hour(id);
CREATE INDEX ON :Minute(id);
CREATE INDEX ON :Second(id);


//Connect hours Sequentially
MATCH (h:Hour)
WITH h
ORDER BY h.id
WITH collect(h) AS hours
FOREACH(i in RANGE(0, size(hours)-2) |
    FOREACH(h1 in [hours[i]] |
        FOREACH(h2 in [hours[i+1]] |
            CREATE UNIQUE (h1)-[:NEXT]->(h2))));



//Connect minutes Sequentially. 
MATCH (h:Hour)-[:HAS]->(mm:Minute)
WITH h, mm
ORDER BY h.id, mm.id
WITH collect(mm) AS minutes
FOREACH(i in RANGE(0, size(minutes)-2) |
    FOREACH(mm1 in [minutes[i]] |
        FOREACH(mm2 in [minutes[i+1]] |
            CREATE UNIQUE (mm1)-[:NEXT]->(mm2))));



//Connect seconds Sequentially. 
MATCH (h:Hour)-[:HAS]->(mm:Minute)-[:DIVIDED]->(ss:Second)
WITH h, mm,ss
ORDER BY h.id, mm.id, ss.id
WITH collect(ss) AS seconds
FOREACH(i in RANGE(0, size(seconds)-2) |
    FOREACH(ss1 in [seconds[i]] |
        FOREACH(ss2 in [seconds[i+1]] |
            CREATE UNIQUE (ss1)-[:NEXT]->(ss2))));



//****************************************************************
//Add the nodes
//****************************************************************


//LOAD CSV script for GFTS data

//Create the constrains
create constraint on (a:Agency) assert a.agencyID is unique;
create constraint on (r:Route) assert r.routeID is unique;
create constraint on (t:Trip) assert t.tripID is unique;
create constraint on (c:Calendar) assert c.cal_serviceID is unique;
create constraint on (s:BusStop) assert s.BusStopID is unique;

schema await

//add the agency
load csv with headers from
'file:///d:\\MonctonGTFS/agency.txt' as csv
create (a:Agency {agencyID:csv.agency_id,agName:csv.agency_name, agUrl:csv.agency_url, AgTimezone:csv.agency_timezone});

// add the routes
load csv with headers from
'file:///d:\\MonctonGTFS/routes.txt' as csv
match (a:Agency {agencyID: csv.agency_id})
create (a)-[:RUNS]->(r:Route {routeID: csv.route_id, rShortName: csv.route_short_name, rLongName: csv.route_long_name, rType: toInt(csv.route_type)});

// add the trips
load csv with headers from
'file:///d:\\MonctonGTFS/trips.txt' as csv
match (r:Route {routeID: csv.route_id})
create (r)<-[:IS_PART_OF]-(t:Trip {tripID: csv.trip_id, serviceID: csv.service_id});

//Adding Calendar
load csv with headers from
'file:///d:\\MonctonGTFS/calendar.txt' as csv
MATCH (t:Trip {serviceID: csv.service_id})
CREATE (t)-[:SCHEDULED_AT]-> (c:Calendar {cal_serviceID:csv.service_id, mon:csv.monday, tue:csv.tuesday, wed:csv.wednesday, thu:csv.thursday, fri:csv.friday, sat:csv.saturday, sun:csv.sunday, startDate: csv.start_date, endDate: csv.end_date});

//add the stops
load csv with headers from
'file:///d:\\MonctonGTFS/stops.txt' as csv
create (bs:BusStop {BusStopID: csv.stop_id, sName: csv.stop_name, sLat: toFloat(csv.stop_lat), sLon: toFloat(csv.stop_lon), sParentStation: csv.parent_station, locType: csv.location_type});


USING PERIODIC COMMIT 1000
load csv with headers from
'file:///d:\\MonctonGTFS/arrival_times.txt' as csv
match (t:Trip {tripID: csv.trip_id}), (bs:BusStop {BusStopID: csv.stop_id})
create (t)-[:COMPOSED_OF]->(be:BusEvent {arrivalTime: csv.arrival_time, departureTime: csv.departure_time, stopSequence: toInt(csv.stop_sequence)})-[:STOPS_AT]->(bs);

CREATE INDEX ON :BusEvent(stopSequence);

MATCH (be1:BusEvent)<-[:COMPOSED_OF]-(t:Trip), (be2:BusEvent)<-[:COMPOSED_OF]-(t)
WHERE be2.stopSequence = be1.stopSequence+1
CREATE (be1)-[:NEXT_BUS_EVENT]->(be2);

//Adding the hour, min and sec to be faster...
MERGE (be:BusEvent)
ON MATCH SET be.hh = toInt(substring(be.arrivalTime,0,2))
ON MATCH SET be.mm = toInt(substring(be.arrivalTime,3,2))
ON MATCH SET be.ss = toInt(substring(be.arrivalTime,6));

CREATE INDEX ON :BusEvent(hh);
CREATE INDEX ON :BusEvent(mm);
CREATE INDEX ON :BusEvent(ss);


//Load Streets
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM 'file:///d:\\Streets1.csv' AS line
CREATE (:Road {roadID: line.FID, roadName: line.STNAME, roadType: line.STTYPE, roadNoSpace:line.NOSPACE});
//CreateIndex
CREATE INDEX ON :Road(roadNoSpace);

//Create the intersections
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM 'file:///d:\\intersections.csv' as input
MATCH (from:Road {roadNoSpace: input.Intersect1}), (to:Road {roadNoSpace: input.Intersect2})
CREATE (from)-[:INTERSECTS]->(to);


//Creating the busStop_isAT_Road relationship
//Create the BusStop_IsAT_Road
LOAD CSV WITH HEADERS FROM 'file:///d:\\BusStop_IsAt_Road.csv' as input
MATCH (from:BusStop {BusStopID:input.UNIQUEID}), (to:Road{roadNoSpace:input.NoSpace})
CREATE (from)-[:LOCATED_AT]->(to);

//Cracks the pc
//MATCH (be:BusEvent) WITH be
//MATCH (hh1:Hour {id:be.hh})-[r1]->(mm1:Minute {id:be.mm}) WITH be,hh1,mm1
//MATCH (mm1)-[r2]->(ss1:Second {id:be.ss}) WITH be, hh1,mm1,ss1
//CREATE (be)-[:HAPPENS_AT]->(ss1)

//Doing this then
MATCH (be:BusEvent) WITH be 
MATCH (hh1:Hour {id:be.hh}) WITH be,hh1
MATCH (hh1)-[r1]->(mm1:Minute {id:be.mm}) WITH be,hh1,mm1
MATCH (mm1)-[r2]->(ss1:Second {id:be.ss}) WITH be, hh1,mm1,ss1
CREATE (be)-[:HAPPENS_AT]->(ss1)

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////IMPORTANT////////////////////////////////////
//////////////////Run this in a command console of windows////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

// FOR %i IN (D:/*.txt) DO Neo4jShell.bat -c "LOAD CSV WITH HEADERS FROM 'file:///%i' as input MATCH (h:Hour {id: toInt(substring(input.arrival_time,0,2))})-[r4]->(mm:Minute {id:toInt(substring(input.arrival_time,3,2))})-[r5]->(ss:Second {id:toInt(substring(input.arrival_time,6))}) WITH h,mm,ss, input MATCH (bs:BusStop {BusStopID:input.stop_id}) WITH h,mm,ss,input,bs CREATE (bs)<-[:STOPS_AT]-(be:BusEvent {trip: input.trip_id, departureTime: input.departure_time, stopSequence: toInt(input.stop_sequence)})-[:ARRIVESS_AT]->(ss) WITH be, input MATCH (t:Trip {tripID: input.trip_id}) WITH be, t CREATE (be)<-[:COMPOSED_OF]-(t);"

// The same that is above but split to be able to read it clearly
//LOAD CSV WITH HEADERS FROM 'file:///%i' as input 
//MATCH (h:Hour {id: toInt(substring(input.arrival_time,0,2))})-[r4]->(mm:Minute {id:toInt(substring(input.arrival_time,3,2))})-[r5]->(ss:Second {id:toInt(substring(input.arrival_time,6))}) WITH h,mm,ss, input 
//MATCH (bs:BusStop {BusStopID:input.stop_id}) WITH h,mm,ss, input, bs
//MATCH (t:Trip {tripID: input.trip_id}) WITH h,mm,ss, input, bs, t
//CREATE (bs)<-[:STOPS_AT]-(be:BusEvent {trip: input.trip_id, departureTime: input.departure_time, stopSequence: toInt(input.stop_sequence)})-[:ARRIVESS_AT]->(ss)
//WITH be, input 
//MATCH (t:Trip {tripID: input.trip_id}) 
//WITH be, t 
//CREATE (be)<-[:COMPOSED_OF]-(t);"
//


//Neo4jShell -file D:\yyyProjects\PublicTransit\Neo4j\queries\GTFS_Moncton.cql