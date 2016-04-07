
MATCH (bs:BusStop)-[r4]-(be:BusEvent)-[r:HAPPENS_AT]->(ss:Second)-[r2]-(mm:Minute)-[r3]-(hh:Hour {id:7}) WITH be,r,r2,r3,r4
MATCH (be)-[r5]-(t:Trip)-[r6]-(ro:Route)
RETURN r,r2,r3,r4,r5,r6 LIMIT 50


//MATCH (h:Hour {id: toInt(substring(input.arrival_time,0,2))})-[r4]->(mm:Minute {id:toInt(substring(input.arrival_time,3,2))})-[r5]->(ss:Second {id:toInt(substring(input.arrival_time,6))})


// *************************************************
// ******** QUERIES TO GTFS DB *********************

// Number of BusEvents
MATCH (be:BusEvent) RETURN 	count(be) as num_events
//Returned 1 row in 8401 ms.
// #3833467


//Number of trips
MATCH (t:Trip) RETURN count(t) as trips
//Returned 1 row in 415 ms.
//101301


//Trips by service 
MATCH (t:Trip) 
RETURN t.serviceID as service, count(t.serviceID) as count
ORDER BY count DESC
//Returned 5 rows in 1056 ms.
//service	count
//1	42981
//2	31631
//3	26548
//401	137
//501	4


//Num of event by hour
MATCH (h:Hour)-[*..3]-(be:BusEvent)
RETURN h.id as hours, count(h) as num_events
ORDER BY num_events DESC
//Returned 23 rows in 27496 ms.
// D:\yyyProjects\PublicTransit\GTFS_Results\NumEventPerHour.csv
//hours	num_events
//17	226663
//16	226021
//18	223148
//15	219142
//14	205787
//13	202517
//9	198990
//12	196571
//8	194896
//19	193731
//11	188984
//10	188493
//7	179761
//20	168071
//21	162982
//22	152851
//6	142332
//23	140462
//0	136331
//1	103597
//5	54902
//4	6421
//3	326


//Num of event by hour and min
MATCH (h:Hour)-[]-(mm:Minute)-[*..2]-(be:BusEvent)
RETURN h.id as hours, mm.id as minutes, count(h) as num_events
ORDER BY num_events DESC
//Returned 1371 rows in 47022 ms, displaying first 1000 rows.
//hours	minutes	num_events
//16	30	3986
//17	0	3962
//18	30	3955
//17	40	3931
//18	0	3923
//17	15	3911
//16	55	3911
//15	30	3909
//18	10	3908
//16	25	3904
//18	25	3903
//16	50	3897
//16	40	3892
//17	10	3883
//18	15	3882
//16	15	3882



// Count number of BusStops
// Show the BusStops with more traffic. 
MATCH (be1:BusEvent)-[r1]-(bs:BusStop) 
RETURN bs.BusStopID as BusStopID, count(r1) as count
ORDER BY count DESC
// D:\yyyProjects\PublicTransit\GTFS_Results\NumOfStopAtBusStops.csv
//Returned 10709 rows in 30169 ms
//BusStopID	count
//13958	2543
//13394	2470
//9276	2388
//13219	2306
//14339	2228
//13482	2155
//9227	2124
//13130	2015
//13059	1945
//13234	1943
//13898	1919


// Show the BusStops with more traffic by Service (1=week day; 2=Sat, 3=Sun, 4&5= specialServices)
MATCH (t:Trip)-[r1]-(be1:BusEvent)-[r2]-(bs:BusStop) 
RETURN bs.BusStopID as BusStopID, t.serviceID as Service, count(r2) as count
ORDER BY count DESC
//Returned 32425 rows in 63908 ms
//BusStopID	Service	count
//13958	1	1153
//9276	1	1086
//13394	1	998
//13898	1	902
//13482	1	882
//13219	1	874
//13234	1	844
//14339	1	842
//13967	1	841
//13130	1	839
//13242	1	792
//13394	2	785
//13219	2	766
//9633	1	754
//4697	1	754
//13958	2	752


//193 Routes

//How many routes stop at each BusStop
MATCH (bs:BusStop)-[r4]-(be:BusEvent)-[r5]-(t:Trip)-[r6]-(ro:Route) 
RETURN bs.BusStopID as BusStopID, collect(distinct ro.routeID) as Routes, count(distinct ro.routeID) as NumRoutes
ORDER BY NumRoutes DESC
// RReturned 10709 rows in 71909 ms
//BusStopID	Routes	NumRoutes
//9276	[41660, 41662, 41663, 41664, 41665, 41675, 41682, 41744, 41815]	9
//2541	[41660, 41661, 41662, 41663, 41665, 41682, 41712, 41815]	8
//14318	[41639, 41640, 41641, 41642, 41651, 41679, 41725, 41749]	8
//8890	[41650, 41652, 41693, 41697, 41698, 41710, 41728, 41811]	8
//9949	[41650, 41652, 41697, 41698, 41710, 41728, 41780, 41811]	8
//6665	[41634, 41637, 41728, 41733, 41739, 41771, 41777, 41779]	8
//5465	[41650, 41652, 41697, 41698, 41710, 41728, 41780, 41811]	8
//4697	[41634, 41637, 41728, 41733, 41739, 41771, 41777, 41779]	8
//9633	[41634, 41637, 41728, 41733, 41739, 41771, 41777, 41779]	8


//Number of BusStops for Routes
MATCH (bs:BusStop)-[r4]-(be:BusEvent)-[r5]-(t:Trip)-[r6]-(ro:Route)
RETURN distinct(ro.routeID) as Route, collect(distinct bs.BusStopID) as BusStopID, count(distinct bs.BusStopID) as NumBusStops
ORDER BY NumBusStops DESC
// Returned 189 rows in 70721 ms.
//Route	BusStopID	NumBusStops
//41821	[1869, 970, 1028, 9886, 14325, 9490, 15209, 8547, 8660, 2206, 1186, 6232, 4795, 1985, 10090, 5790, 2179, 2207, 4634, 3545, 
//2811, 2016, 5272, 3130, 5761, 4758, 9357, 957, 1205, 9692, 7563, 4871, 6802, 5237, 5990, 6521, 7439, 1995, 10410, 4277, 10109, 
//3457, 8004, 2458, 894, 3373, 14827, 5935, 5041, 9910, 9369, 6631, 2771, 9515, 14955, 941, 8142, 2993, 7735, 8453, 648, 15248, 5030, 
//1367, 8359, 2315, 3409, 5394, 9282, 6800, 1162, 5897, 5484, 7889, 2199, 4997, 5035, 7569, 6511, 3737, 3837, 1188, 14317, 2038, 2305, 
//14810, 5779, 9672, 6601, 5592, 2989, 14598, 14599, 1698, 14604, 14602, 14607, 14605, 1293, 7685, 4513, 4255, 4442, 1240, 7817, 9275, 
//2559, 10177, 6583, 7712, 15249, 5918, 5685, 5768, 5412, 7325, 9527, 2920, 647, 6105, 3990, 5331, 7551, 9433, 3861, 9741, 996, 4278, 
//5435, 5099, 1074, 5892, 3309, 5772, 8063, 10211, 1901, 15210, 4755, 3132, 5752, 6173, 1167, 4868, 3272, 6005, 4267, 6189, 4152, 5809, 
//6664, 8645, 9514, 2978, 8318, 4647, 8120, 6874, 1930, 8971, 7617, 5623, 3913, 893, 5357, 8411, 3393, 2474, 8362, 1171, 13866, 895, 8737, 
///10047, 4926, 4074, 7526, 9674, 8187, 9539, 3193, 14608, 14609, 3713, 6488, 7762, 14606, 14603, 14601, 14600, 4931, 3252, 650, 3135, 563, 
//4060, 3090, 1041, 370, 8880, 9588, 1896, 1936, 4555, 14687, 8218, 8139, 2313, 14095, 14093, 14094, 14091, 14092, 7766, 7840, 7911, 14106, 
//14105, 14104, 9731, 758, 1399, 14107, 3154, 4762, 5183, 15108, 14076, 14075, 14074, 6161, 8432, 1501, 14692, 356, 3547, 4269, 9425, 4659, 
//7780, 7428, 1674, 2475, 2907, 14081, 13982, 14082, 13745, 14083, 14108, 13795, 6739, 13942, 13517, 14980, 14079, 14080, 14078, 14077, 717, 897, 14014]	262


//Number of trips (Trip and #repetitions in that hour) per hour
MATCH (h:Hour)-[*..3]-(be:BusEvent)-[r5]-(t:Trip)
WITH  h.id as hours, t.tripID as trip, count(*) as tripCount
RETURN hours, collect([trip, tripCount])
//Returned 23 rows in 106428 ms.
//hours	collect([trip, tripCount])
//23	[[28924963, 27], [29088650, 17], [29077921, 18], [28925713, 4], [29091233, 26], [29085343, 30], [28950321, 15], [29126769, 23], .....


//Number of trips (with routes) per hour. 
MATCH (h:Hour)-[*..3]-(be:BusEvent)-[r5]-(t:Trip)-[r6]-(ro:Route) 
WITH  h.id as hours, t.tripID as trip, count(*) as tripCount, ro.routeID as Route
RETURN hours,Route,collect(distinct(trip)) 
//Returned 3292 rows in 453552 ms
//hours	collect(distinct(trip))	Route
//7	[28941487, 29086232, 28941580, 28941567, 29086181, 29086228, 28941546, 28941484, 28941490, 28941489, 28941564, 29086177, 28941486, 29086231, 29086180, 28941569, 28941488, 28941566, 28941485, 29086230, 29086179, 28941568, 29086229, 28941491, 28941565, 29086178]	41762
//8	[28938782, 28938770, 29084257, 29084371, 28938769, 29113836, 28938635, 28938623, 29084263, 29113899, 29084379, 29084367, 28938766, 29084260, 28938620, 29084259, 28938619, 29084385, 28938784, 28938637, 28938763, 29113788, 28938781, 29084256, 28938628, 28938772, 29113785, 28938634, 29084262, 29113740, 29113901, 28938625, 28938765, 29113838, 29084366, 28938768, 28938783, 29084384, 28938622, 29084363, 28938762, 29113787, 28938639, 28938780, 29084255, 28938627, 29113739, 29113784, 28938771, 28938618, 29084258, 29113837, 28938624, 29113900, 28938636, 29084368, 28938767, 28938785, 29084261, 28938621, 28938773, 29084386, 29113786, 29084362, 28938626, 29113738, 28938764, 29113840, 29113839, 28938638]	41752



