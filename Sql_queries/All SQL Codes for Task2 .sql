// Query 1 : All Teams Data --------------------------------------------------------------------------------------------------------
SELECT
  
  CONCAT('TIDCSC',ROW_NUMBER() OVER (ORDER BY EmployeesId)) AS UniqueId,
  'Charging station check' AS TaskType,
  EmployeesName,
  EmployeesId,
  Quantity,
  TaskAverageTime,
  AvgDistanceTakenToReachSite,
  AvgTimeTakenToReachSite
FROM
  SampleTestingDataset.TeamChargingStationCheck

UNION ALL

SELECT
  
  CONCAT('TIDCSI',ROW_NUMBER() OVER (ORDER BY EmployeesId)) AS UniqueId,
  'Charging station installation' AS TaskType,
  EmployeesName,
  EmployeesId,
  Quantity,
  TaskAverageTime,
  AvgDistanceTakenToReachSite,
  AvgTimeTakenToReachSite
FROM
  SampleTestingDataset.TeamChargingStationInstallation

UNION ALL

SELECT
  
  CONCAT('TIDVM',ROW_NUMBER() OVER (ORDER BY EmployeesId)) AS UniqueId,
  'Vehicle maintenance' AS TaskType,
  EmployeesName,
  EmployeesId,
  Quantity,
  TaskAverageTime,
  AvgDistanceTakenToReachSite,
  AvgTimeTakenToReachSite
FROM
  SampleTestingDataset.TeamVehicleMaintenance;
  
  // Query 2 :Completed Tasks With Travelling Info --------------------------------------------------------------------------------
  
  SELECT
  CT.*,
  DTPC.City AS ClientCity,
  DTPC.PostalCode,
  DT.Distance__Km_ AS DistanceTakenToReachSite,
  DT.Time__hrs_ AS TimeTakenToReachSite,
FROM
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsCompletedTasks` AS CT
JOIN
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsOpenContracts` AS OC
ON
  CT.ContractId = OC.ContractId
JOIN
  `proj-iv-maintenance-service.SampleTestingDataset.DistancesAndTimeServicePointToClient` AS DT
ON
  OC.ClientId = DT.ClientId
JOIN
  `proj-iv-maintenance-service.SampleTestingDataset.DistancesAndTimeServicePointToClient` AS DTPC
ON
  OC.ClientId = DTPC.ClientId
ORDER BY
  ServiceTaskId ASC;
  
  // Query 3 :Multi Employee Tasks  -------------------------------------------------------------------------------------------
  
  SELECT
  ct.ServiceTaskId,
  te1.ServiceEmployeeId AS Employee1Id,
  te1.Name AS Employee1Name,
  te2.ServiceEmployeeId AS Employee2Id,
  te2.Name AS Employee2Name,
  ct.TaskType,
  ct.Quantity,
  ROUND((ct.TotalWorkingHours / ct.Quantity), 2) AS AverageTime,
  ct.DistanceTakenToReachSite,
  ct.TimeTakenToReachSite,
FROM
  `proj-iv-maintenance-service.SampleTestingDataset.CompletedTaskWithTravellingInfo` AS ct
JOIN
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsAssignedEmployees` AS ae1
ON
  ct.ServiceTaskId = ae1.ServiceTaskId
JOIN
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsAssignedEmployees` AS ae2
ON
  ct.ServiceTaskId = ae2.ServiceTaskId
JOIN
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsServiceEmployees` AS te1
ON
  ae1.ServiceEmployeeId = te1.ServiceEmployeeId
JOIN
  `proj-iv-maintenance-service.MwwMsSAPData.MwwMsServiceEmployees` AS te2
ON
  ae2.ServiceEmployeeId = te2.ServiceEmployeeId
WHERE
  te1.ServiceEmployeeId < te2.ServiceEmployeeId
  
  // Query 4 :Tasks Which Require More Than One Employee -------------------------------------------------------------------------
  
  
SELECT ServiceTaskId
FROM `proj-iv-maintenance-service.MwwMsSAPData.MwwMsAssignedEmployees`
GROUP BY ServiceTaskId
HAVING COUNT(DISTINCT ServiceEmployeeId) > 1;

// Query 5 :Team Info with Specifics Task ---------------------------------------------------------------------------------------------

SELECT
  *
FROM
  `proj-iv-maintenance-service.SampleTestingDataset.MultiEmployeetasks-TravellingInfo`
  where Tasktype ='Charging station installation'
  
  // Query 6 :Team Task Type with Gender
  SELECT
    CONCAT(Employee1Name, ' and ', Employee2Name) AS Team,
    CASE
        WHEN e1.Gender = 'M' AND e2.Gender = 'M' THEN 'Male Team'
        WHEN e1.Gender = 'F' AND e2.Gender = 'F' THEN 'Female Team'
        ELSE 'Couple Team'
    END AS TeamGender,
    COUNT(*) AS Quantity,
    ROUND(SUM(TotalWorkingHours), 2) AS TotalWorkingHours,
    ROUND(AVG(AverageTime), 2) AS AverageTime,
    ROUND(AVG(DistanceTakenToReachSite), 2) AS AvgDistanceTakenToReachSite,
    ROUND(AVG(TimeTakenToReachSite), 2) AS AvgTimeTakenToReachSite
FROM
    SampleTestingDataset.ChargingStationInstallationWithTravellingInfo
JOIN
    `MwwMsSAPData.MwwMsServiceEmployees` AS e1 ON Employee1Id = e1.ServiceEmployeeId
JOIN
    `MwwMsSAPData.MwwMsServiceEmployees` AS e2 ON Employee2Id = e2.ServiceEmployeeId
GROUP BY
    Team, TeamGender
ORDER BY
    Quantity DESC;