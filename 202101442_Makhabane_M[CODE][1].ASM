.data
soil_fertility:     .word 3          # initial soil fertility level
moisture_content:    .word 4          # initial moisture content level
crop_yield:          .word 0          # Variable to store the overall crop yield
season: .word 0 # 0 for winter, 1 for summer
cropStatus: .space 100 # Array to store crop status
harvestMsg: .asciiz "Harvested "
winter_msg: .asciiz "--- Starting Season Winter ---\n"
summer_msg: .asciiz "--- Starting Season Summer ---\n"
end_season_msg: .asciiz "--- Ending Season ---\n\n"
wheat_msg: .asciiz "--- Planting Wheat ---\n"
summer_crop_msg: .asciiz "--- Planting Summer Crop ---\n"
summer_harvest_msg: .asciiz "--- Harvesting Summer Crop ---\n"
winter_harvest_msg: .asciiz "--- Harvesting Winter Crop ---\n"
bad_yeild_msg: .asciiz "--- Bad yeild produced ---\n"
newline: .asciiz "\n"


.text

main:
	li $t0, 4 # April (Month Register)
	li $t1, 1 # Winter season initially (Season Register)
	li $t2, 1 # Wheat planting month  (Planting Month Register)
	li $t3, 3 # Wheat harvest month (Harvest Month Register)
	
	# Call subroutine for soil fertility and moisture management
        jal check_soil

        # Call subroutine for crop yield calculation
        jal calculate_yield 
	j simulateAnnualCycle

plantCrops:
	# Simulate planting of crops based on the current season
	beq $t1, 0, winter_planting
	beq $t1, 1, summer_intercropping

summer_intercropping:
	# Check if planting month is within the summer planting season (August to October)
	blt $t2, 8, end_planting
	bge $t2, 11, end_planting
	j plant_summer_crop

plant_next_crop:
	# Load base address of cropStatus array into $t4
	la $t4, cropStatus
	
	# Calculate the index for the current crop in the cropStatus array
	mul $t5, $t2, 3 # Each crop status has 3 words: planting month, harvest month, and yield
	add $t4, $t4, $t5
	
	# Check the current season
	beq $t1, 0, winter_planting
	beq $t1, 1, summer_intercropping


winter_planting:
	# Check if planting month is within the winter planting season (April to May)
	bge $t2, 4, end_planting
	bge $t2, 1, plant_wheat
	j end_planting


plant_wheat:
	
	sw $t2, 0($t4) # Store planting month
	sw $t3, 4($t4) # Store harvest month (January to March)
	sw $zero, 8($t4) # Initialize yield to 0.0
	
	# Display a message indicating the planted crop (optional)
	li $v0, 4
	la $a0, wheat_msg
	syscall
	j end_planting


plant_summer_crop:
	
	sw $t2, 0($t4) # Store planting month
	sw $t3, 4($t4) # Store harvest month (November to December)
	sw $zero, 8($t4) # Initialize yield to 0.0
	
	# Display a message indicating the planted crop (optional)
	li $v0, 4
	la $a0, summer_crop_msg
	syscall
	j end_planting

end_planting:
	j simulateAnnualCycle


harvestCrops:
	# Simulate harvesting of crops based on the current season
	beq $t1, 0, winter_harvesting
	beq $t1, 1, summer_harvesting

winter_harvesting:
	beq $t3, 3, end_harvesting # Harvesting period for winter crops (January to March)
	
	# Display a message indicating the harvested crop
	li $v0, 4
	la $a0, winter_harvest_msg
	syscall
	
	# Update cropStatus array accordingly
	li $t7, 10 # Placeholder yield value, replace with your calculation
	sw $t7, 8($t4) # Update yield in cropStatus
	sw $zero, 0($t4) # Clear planting month
	sw $zero, 4($t4) # Clear harvest month
	
	j harvest_next_crop


summer_harvesting:
	beq $t3, 12, end_harvesting # Harvesting period for summer crops (November to December)
	
	# Display a message indicating the harvested crop (optional)
	li $v0, 4
	la $a0, summer_harvest_msg
	syscall
	
	# Update cropStatus array accordingly
	li $t7, 15 # Placeholder yield value, replace with your calculation
	sw $t7, 8($t4) # Update yield in cropStatus
	sw $zero, 0($t4) # Clear planting month
	sw $zero, 4($t4) # Clear harvest month
	
	j harvest_next_crop


harvest_next_crop:
	# Load base address of cropStatus array into $t4
	la $t4, cropStatus
	
	# Calculate the index for the current crop in the cropStatus array
	mul $t5, $t3, 3 # Each crop status has 3 words: planting month, harvest month, and yield
	add $t4, $t4, $t5
	
	lw $t6, 4($t4) # Load the harvest month from cropStatus
	
	# Check if the current month is the harvest month
	beq $t6, 1, winter_harvest(use t6 for harvest month)
	beq $t6, 11, summer_harvest
	
	j end_harvesting


end_harvesting:
	# Increment the harvest month counter
	addi $t3, $t3, 1
	j simulateAnnualCycle


simulateAnnualCycle:
	# Check for end of the year
	bge $t0, 13, end_simulation
	# Check for season change
	bnez $t0, check_season
	j next_month


check_season:
	# Check for winter (April-May)
	blt $t0, 4, summer_check
	bnez $t1, next_month
	li $t1, 1 # Switch to summer
	j next_month


summer_check:
	# Check for summer (August-October)
	bge $t0, 8, next_month
	bnez $t1, next_month
	li $t1, 0 # Switch to winter

next_month:
	# Increment the month counter
	addi $t0, $t0, 1
	j plantCrops 

# Subroutine to check soil fertility and moisture content
check_soil:
    lw $t0, soil_fertility       # Load soil fertility level
    lw $t1, moisture_content     # Load moisture content level

    # Compare soil fertility and moisture levels
    li $t2, 5                     # Threshold for bad soil fertility
    blt $t0, $t2, bad_yield       # Branch if soil fertility is below threshold

    li $t3, 5                     # Threshold for bad moisture content
    blt $t1, $t3, bad_yield       # Branch if moisture content is below threshold

    # Good soil fertility and moisture content
    j end_check_soil

bad_yield:
       # Display a message indicating the planted crop (optional)
	li $v0, 4
	la $a0, bad_yeild_msg
	syscall

end_check_soil:
    jr $ra

# Subroutine to calculate crop yield
calculate_yield:
    # Load relevant parameters (soil fertility, moisture content)
    lw $t0, soil_fertility
    lw $t1, moisture_content

    # overall yield = soil fertility * moisture content
    mul $t2, $t0, $t1
    sw $t2, crop_yield

    jr $ra

end_simulation:
	# Exit the program
	li $v0, 10
	syscall