-- Creating database
create database noesys_s;

-- Selecting database
use noesys_s;

-- Reading 'whatsmybill'
select * from whatsmybill;

-- Removing first delimeter
WITH RECURSIVE removing_first_delimeter AS (
    SELECT 
        Plan_ID,
        PlanName,
        Usage_,
        BillValue,
        SUBSTRING_INDEX(UsageRateSlabs, '|', 1) AS S1,
        CASE WHEN LENGTH(UsageRateSlabs) - LENGTH(REPLACE(UsageRateSlabs, '|', '')) >= 1 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(UsageRateSlabs, '|', 2), '|', -1) ELSE NULL END AS S2,
        CASE WHEN LENGTH(UsageRateSlabs) - LENGTH(REPLACE(UsageRateSlabs, '|', '')) >= 2 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(UsageRateSlabs, '|', 3), '|', -1) ELSE NULL END AS S3,
        CASE WHEN LENGTH(UsageRateSlabs) - LENGTH(REPLACE(UsageRateSlabs, '|', '')) >= 3 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(UsageRateSlabs, '|', 4), '|', -1) ELSE NULL END AS S4,
        CASE WHEN LENGTH(UsageRateSlabs) - LENGTH(REPLACE(UsageRateSlabs, '|', '')) >= 4 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(UsageRateSlabs, '|', 5), '|', -1) ELSE NULL END AS S5
    FROM 
        whatsmybill
),
-- Removing second delimeter
removing_second_delimeter AS (
    SELECT 
        Plan_ID, 
        PlanName, 
        Usage_, 
        BillValue,
        SUBSTRING_INDEX(S1, ',', 1) AS S1Limit,
        SUBSTRING_INDEX(S1, ',', -1) AS Rate1,
        SUBSTRING_INDEX(S2, ',', 1) AS S2Limit,
        SUBSTRING_INDEX(S2, ',', -1) AS Rate2,
        SUBSTRING_INDEX(S3, ',', 1) AS S3Limit,
        SUBSTRING_INDEX(S3, ',', -1) AS Rate3,
        SUBSTRING_INDEX(S4, ',', 1) AS S4Limit,
        SUBSTRING_INDEX(S4, ',', -1) AS Rate4,
        SUBSTRING_INDEX(S5, ',', 1) AS S5Limit,
        SUBSTRING_INDEX(S5, ',', -1) AS Rate5
    FROM 
        removing_first_delimeter
),
-- final calculation for required output
result AS (
    SELECT 
        Plan_ID, 
        PlanName, 
        Usage_, 
        BillValue,
        CASE 
            WHEN Usage_ <= S1Limit THEN Usage_ * Rate1
            WHEN Usage_ > S1Limit AND Usage_ <= (S1Limit + IFNULL(S2Limit, 0)) THEN S1Limit * Rate1 + (Usage_ - S1Limit) * Rate2
            WHEN Usage_ > (S1Limit + IFNULL(S2Limit, 0)) AND Usage_ <= (S1Limit + IFNULL(S2Limit, 0) + IFNULL(S3Limit, 0)) THEN S1Limit * Rate1 + S2Limit * Rate2 + (Usage_ - (S1Limit + S2Limit)) * Rate3
            WHEN Usage_ > (S1Limit + IFNULL(S2Limit, 0) + IFNULL(S3Limit, 0)) AND Usage_ <= (S1Limit + IFNULL(S2Limit, 0) + IFNULL(S3Limit, 0) + IFNULL(S4Limit, 0)) THEN S1Limit * Rate1 + S2Limit * Rate2 + S3Limit * Rate3 + (Usage_ - (S1Limit + S2Limit + S3Limit)) * Rate4
            ELSE S1Limit * Rate1 + S2Limit * Rate2 + S3Limit * Rate3 + S4Limit * Rate4 + (Usage_ - (S1Limit + S2Limit + S3Limit + S4Limit)) * Rate5 
        END AS final_result
    FROM 
        removing_second_delimeter
)
-- Reading final table
SELECT 
    Plan_ID, 
    PlanName, 
    Usage_, 
    BillValue,
    final_result
FROM 
    result;