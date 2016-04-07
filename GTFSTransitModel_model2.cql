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
'file:///d:\\TorontoGTFS/agency.txt' as csv
create (a:Agency {agencyID: toInt(csv.agency_id), agName: csv.agency_name, agUrl: csv.agency_url, AgTimezone: csv.agency_timezone});

// add the routes
load csv with headers from
'file:///d:\\TorontoGTFS/routes.txt' as csv
match (a:Agency {agencyID: toInt(csv.agency_id)})
create (a)-[:RUNS]->(r:Route {routeID: csv.route_id, rShortName: csv.route_short_name, rLongName: csv.route_long_name, rType: toInt(csv.route_type)});

// add the trips
load csv with headers from
'file:///d:\\TorontoGTFS/trips.txt' as csv
match (r:Route {routeID: csv.route_id})
create (r)<-[:IS_PART_OF]-(t:Trip {tripID: csv.trip_id, serviceID: csv.service_id});

//add calendar
//'file:///d:\\TorontoGTFS/calendar.txt' as csv
//match (t:Trip {serviceID: csv.service_id})
//create (t)-[:SCHEDULED_AT]-> (c:Calendar {cal_serviceID:csv.service_id, mon:csv.monday, tue:csv.tuesday, wed:csv.wednesday, thu:csv.thursday, fri:csv.friday, sat:csv.saturday, sun:csv.sunday, startDate: csv.start_date, endDate: csv.end_date});

//add the stops
load csv with headers from
'file:///d:\\TorontoGTFS/stops.txt' as csv
create (bs:BusStop {BusStopID: csv.stop_id, sName: csv.stop_name, sLat: toFloat(csv.stop_lat), sLon: toFloat(csv.stop_lon), sParentStation: csv.parent_station, locType: csv.location_type});


//Neo4jShell -file D:\yyyProjects\PublicTransit\Neo4j\queries\GTFSTransitModel_model2.cql


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



USING PERIODIC COMMIT 1000
load csv with headers from
'file:///d:\\TorontoGTFS/arrival_times.txt' as csv
match (t:Trip {tripID: csv.trip_id}), (bs:BusStop {BusStopID: csv.stop_id})
create (t)-[:COMPOSED_OF]->(be:BusEvent {arrivalTime: csv.arrival_time, departureTime: csv.departure_time, stopSequence: toInt(csv.stop_sequence)})-[:STOPS_AT]->(bs);

CREATE INDEX ON :BusEvent(stopSequence);

match (be1:BusEvent)<-[:COMPOSED_OF]-(t:Trip), (be2:BusEvent)<-[:COMPOSED_OF]-(t)
where be2.stopSequence > be1.stopSequence
create (s1)-[:NEXT_BUS_EVENT]->(s2);