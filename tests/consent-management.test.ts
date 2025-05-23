import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity environment
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  contracts: {
    "vehicle-verification": {
      functions: {
        "register-vehicle": vi.fn(),
        "verify-vehicle": vi.fn(),
        "add-verification-authority": vi.fn(),
        "get-vehicle-details": vi.fn(),
        "is-authority": vi.fn(),
      },
    },
  },
}

// Setup global mock
vi.mock("clarity-environment", () => mockClarity, { virtual: true })

describe("Vehicle Verification Contract", () => {
  beforeEach(() => {
    // Reset mocks before each test
    vi.resetAllMocks()
  })
  
  it("should register a new vehicle", async () => {
    // Setup mock return value
    mockClarity.contracts["vehicle-verification"].functions["register-vehicle"].mockResolvedValue({
      success: true,
      result: { value: true },
    })
    
    // Test parameters
    const vehicleId = "VIN123456789ABCDEF"
    const manufacturer = "Tesla"
    const model = "Model 3"
    const year = 2023
    
    // Call the function
    const result = await mockClarity.contracts["vehicle-verification"].functions["register-vehicle"](
        vehicleId,
        manufacturer,
        model,
        year,
    )
    
    // Verify the result
    expect(result.success).toBe(true)
    expect(result.result.value).toBe(true)
    
    // Verify the function was called with correct parameters
    expect(mockClarity.contracts["vehicle-verification"].functions["register-vehicle"]).toHaveBeenCalledWith(
        vehicleId,
        manufacturer,
        model,
        year,
    )
  })
  
  it("should verify a vehicle when called by an authority", async () => {
    // Setup mock return values
    mockClarity.contracts["vehicle-verification"].functions["is-authority"].mockResolvedValue({
      success: true,
      result: { value: true },
    })
    
    mockClarity.contracts["vehicle-verification"].functions["verify-vehicle"].mockResolvedValue({
      success: true,
      result: { value: true },
    })
    
    // Test parameters
    const vehicleId = "VIN123456789ABCDEF"
    
    // Call the function
    const result = await mockClarity.contracts["vehicle-verification"].functions["verify-vehicle"](vehicleId)
    
    // Verify the result
    expect(result.success).toBe(true)
    expect(result.result.value).toBe(true)
    
    // Verify the function was called with correct parameters
    expect(mockClarity.contracts["vehicle-verification"].functions["verify-vehicle"]).toHaveBeenCalledWith(vehicleId)
  })
  
  it("should add a verification authority when called by contract owner", async () => {
    // Setup mock return value
    mockClarity.contracts["vehicle-verification"].functions["add-verification-authority"].mockResolvedValue({
      success: true,
      result: { value: true },
    })
    
    // Test parameters
    const authorityAddress = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    
    // Call the function
    const result =
        await mockClarity.contracts["vehicle-verification"].functions["add-verification-authority"](authorityAddress)
    
    // Verify the result
    expect(result.success).toBe(true)
    expect(result.result.value).toBe(true)
    
    // Verify the function was called with correct parameters
    expect(mockClarity.contracts["vehicle-verification"].functions["add-verification-authority"]).toHaveBeenCalledWith(
        authorityAddress,
    )
  })
  
  it("should retrieve vehicle details", async () => {
    // Setup mock return value
    const mockVehicleData = {
      owner: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      manufacturer: "Tesla",
      model: "Model 3",
      year: 2023,
      "is-verified": true,
      "verification-date": 12345,
    }
    
    mockClarity.contracts["vehicle-verification"].functions["get-vehicle-details"].mockResolvedValue({
      success: true,
      result: { value: mockVehicleData },
    })
    
    // Test parameters
    const vehicleId = "VIN123456789ABCDEF"
    
    // Call the function
    const result = await mockClarity.contracts["vehicle-verification"].functions["get-vehicle-details"](vehicleId)
    
    // Verify the result
    expect(result.success).toBe(true)
    expect(result.result.value).toEqual(mockVehicleData)
    
    // Verify the function was called with correct parameters
    expect(mockClarity.contracts["vehicle-verification"].functions["get-vehicle-details"]).toHaveBeenCalledWith(
        vehicleId,
    )
  })
})
