-- TEST_TOP_SPENDERS.luau
-- Script untuk test API top spenders endpoint
-- Letakkan di ServerScriptService untuk testing

local HttpService = game:GetService("HttpService")

local WEBHOOK_API_BASE = "https://webhook-integration-zeta.vercel.app/" -- Ganti dengan URL Anda

local function testTopSpendersAPI()
	print("=== TESTING TOP SPENDERS API ===")
	
	local url = string.format("%s/api/roblox/top-spenders?limit=10", WEBHOOK_API_BASE)
	print("📡 URL:", url)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	
	if not success then
		warn("❌ HTTP Request failed:", response)
		return
	end
	
	print("✅ HTTP Request successful")
	print("📦 Raw response:", response)
	
	local parseSuccess, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)
	
	if not parseSuccess then
		warn("❌ JSON Parse failed:", data)
		return
	end
	
	print("✅ JSON Parse successful")
	print("📊 Data structure:")
	print("  - ok:", data.ok)
	print("  - count:", data.count)
	print("  - topSpenders count:", #(data.topSpenders or {}))
	
	if data.ok and data.topSpenders then
		print("\n🏆 Top Spenders:")
		for i, spender in ipairs(data.topSpenders) do
			print(string.format("  [%d] %s - %d", i, spender.username or "nil", spender.totalAmount or 0))
		end
	else
		warn("⚠️ No top spenders data!")
	end
	
	print("\n=== TEST COMPLETED ===")
end

-- Run test
task.wait(1)
testTopSpendersAPI()
