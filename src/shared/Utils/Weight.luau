local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RblxUtils = require(ReplicatedStorage.Packages.RblxUtils)
local Weight = {}

function Weight.getRandomKeyFromDictionary(dict: {[unknown]: number}, random: Random?)
	local totalWeight = 0
	for _, weight in dict do
		if typeof(weight) == "number" then
			totalWeight += weight
		end
	end
	local counter =	(random or Random.new()):NextNumber(0, totalWeight)
	for key, weight in dict do
		counter -= weight
		if counter <= 0 then
			return key
		end
	end
end


-- Postive factor = less likely events more likley to happen
-- Negative factor = more likely events less likely to happen
function Weight.skew<T>(dict: T & {[unknown]: number}, factor: number)
	local keys = RblxUtils.Table.keys(dict)
	local skewed: T & {[unknown]: number} = {};
  
	-- Base factor to adjust the weights
	--local baseFactor = 1 - factor;
	local baseFactor = factor
  
	-- Apply the skewing factor to each entry's weight
	for i,v in dict do
		local newWeight = v ^ baseFactor;
		skewed[i] = newWeight;
	end
  
	-- Calculate the new total weight after skewing
	local newTotalWeight = 0
	for i,v in skewed do
		newTotalWeight += v
	end
  
	-- Normalize the skewed rates to ensure they add up to 1
	for _, i in keys do
		skewed[i] /= newTotalWeight;
	end
  
	return skewed;
end

return Weight