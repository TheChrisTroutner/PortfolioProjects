/*
Cleaning data in SQL queries
NOTE: there is a significant amount of NULL data for this data set,
with only ParcelID, LandUse, PropertyAddress, SaleDate, and SalePrice, and SoldAsVacant populated with data
for less than half of the data set, thus limiting the useful of this data for analysis, but for purposes
of this project, we are focusing on cleaning a data set.
*/

SELECT *
FROM ProjectPortfolio.dbo.HousingData;

--Standardize SaleDate format
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM ProjectPortfolio.dbo.HousingData;

Update ProjectPortfolio.dbo.HousingData
SET SaleDate = CONVERT(date, SaleDate);

ALTER TABLE ProjectPortfolio.dbo.HousingData
ADD SaleDateConverted DATE;

UPDATE ProjectPortfolio.dbo.HousingData
SET SaleDateConverted = CONVERT(DATE, SaleDate)

-- Populate Property Address data
SELECT *
FROM ProjectPortfolio.dbo.HousingData
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID, PropertyAddress;

--self join to Identify missing addresses but same parcel IDs
SELECT p1.ParcelID, p1.PropertyAddress, p2.ParcelID, p2.PropertyAddress
FROM ProjectPortfolio.dbo.HousingData AS p1
JOIN ProjectPortfolio.dbo.HousingData AS p2
	ON p1.ParcelID = p2.ParcelID
	AND p1.[UniqueID ] <> p2.[UniqueID ]
WHERE p1.PropertyAddress IS NULL;

--updates property address where Null existed with property address from the same parcel ID if it exists
UPDATE p1
SET PropertyAddress = ISNULL(p1.PropertyAddress, p2.PropertyAddress)
FROM ProjectPortfolio.dbo.HousingData AS p1
JOIN ProjectPortfolio.dbo.HousingData AS p2
	ON p1.ParcelID = p2.ParcelID
	AND p1.[UniqueID ] <> p2.[UniqueID ]
WHERE p1.PropertyAddress IS NULL;

--Breaking out property address into individual columns
SELECT *
FROM ProjectPortfolio.dbo.HousingData;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Poperty_City
FROM ProjectPortfolio.dbo.HousingData;

ALTER TABLE ProjectPortfolio.dbo.HousingData
ADD PropertyStreetAddress NVARCHAR(255);

UPDATE ProjectPortfolio.dbo.HousingData
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE ProjectPortfolio.dbo.HousingData
ADD PropertyCity NVARCHAR(255);

UPDATE ProjectPortfolio.dbo.HousingData
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- owner address
SELECT *
FROM ProjectPortfolio.dbo.HousingData;

SELECT
PARSENAME(REPLACE( OwnerAddress, ',', '.'),3),
PARSENAME(REPLACE( OwnerAddress, ',', '.'),2),
PARSENAME(REPLACE( OwnerAddress, ',', '.'),1)
FROM ProjectPortfolio.dbo.HousingData;

ALTER TABLE ProjectPortfolio.dbo.HousingData
ADD	OwnerStreetAddress NVARCHAR(255),
	OwnerCity NVARCHAR(255),
	OwnerState NVARCHAR(55);

UPDATE ProjectPortfolio.dbo.HousingData
SET		OwnerStreetAddress = PARSENAME(REPLACE( OwnerAddress, ',', '.'),3),
		OwnerCity = PARSENAME(REPLACE( OwnerAddress, ',', '.'),2),
		OwnerState = PARSENAME(REPLACE( OwnerAddress, ',', '.'),1);

--Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM ProjectPortfolio.dbo.HousingData
GROUP BY SoldAsVacant;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM ProjectPortfolio.dbo.HousingData

UPDATE ProjectPortfolio.dbo.HousingData
	SET SoldAsVacant =	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;

--Remove Duplicates
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
									ORDER BY UniqueID) AS row_num
FROM ProjectPortfolio.dbo.HousingData)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
									ORDER BY UniqueID) AS row_num
FROM ProjectPortfolio.dbo.HousingData)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


--Create a new table with the final columns
SELECT
		UniqueID,
		ParcelID,
		LandUse,
		SalePrice,
		LegalReference,
		SoldAsVacant,
		OwnerName,
		Acreage,
		BuildingValue,
		TotalValue,
		YearBuilt,
		SaleDateConverted,
		PropertyStreetAddress,
		PropertyCity,
		OwnerStreetAddress,
		OwnerCity,
		OwnerState

INTO ProjectPortfolio.dbo.housing_data_updated
FROM ProjectPortfolio.dbo.HousingData;

SELECT *
FROM ProjectPortfolio.dbo.HousingData
WHERE OwnerName IS NOT NULL
ORDER BY SaleDate DESC;