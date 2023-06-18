
--Cleaning Data in SQL Queries

SELECT *
FROM NashvilleHousing

--Standarize date
---Will add a column to the table for more clarity and to set column-new colunmn will be
---SaleDateConvertd from the original Saledate

SELECT SaleDateConverted
FROM NashvilleHousing

UPDATE NashvilleHousing 
SET SaleDate = CONVERT(varchar, getdate(),1)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

--Now will look at Null values in different address columns and match to table key to confirm.
--Then will copy information over to get rid of Nulls.

SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

--Compare to everything and pull out specifically for Nulls in among the property addresses

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

--Will need to look at a reference point to see if there is a way to compare to other information in order
--to find way to get rid of the null values.

SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL.
ORDER BY ParcelID

--Will compare the parcel ID, as there are multiple duplicates and then will match the address.
--Where there is an address as null we will replace that one with the one, if there is one,
--with the address that exists.  Parcel IDs must match.
--Will use "Self-Join" to the table
--Will use ISNULL in order to see in the missing addresses for matching


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID =b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

--Now that we have the missing addresses need to update the actual column currently containing null values.

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID =b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

--Null values have not been removed.

--Now going to take the Address Column, which includes a full address with the City and state
--and break that into multiple columns. Will use SUBSTRING and CHARINDEX.

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR (255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR (255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

--Going to try a different method for separating out the address lines with the OwnerAddress Colunmn
--using PARSENAME

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM NashvilleHousing

--Now to update the table

--Address

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR (255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

--City

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR (255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

--State

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR (255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

--Put the Columns in the wrong worder, will need to create a VIEW with the Columns in the proper order
--when ready; OwnerSplitAddress, OwnerSplitCity, OwnerSplitState.

--Looking at SoldAsVacant column, want to change the binary responses for consistency. 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
	

--Will now remove some duplicates.  Will create a CTE to work off of.

SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) AS row_num
FROM NashvilleHousing
ORDER BY ParcelID

--Will now create the CTE to remove the duplicate rows using the query above

WITH RowNumCTE AS( 
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) AS row_num
FROM NashvilleHousing)
--ORDER BY ParcelID
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Will now delete the duplicates with the CTE we created

WITH RowNumCTE AS( 
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) AS row_num
FROM NashvilleHousing)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--To check to make sure all duplicates are gone:

WITH RowNumCTE AS( 
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) AS row_num
FROM NashvilleHousing)
Select *
FROM RowNumCTE
WHERE row_num > 1


--Will now remove unneccessary columns
--At this point might consider creating a view to retain just the data we need on a project
--rather than deleting.  

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate