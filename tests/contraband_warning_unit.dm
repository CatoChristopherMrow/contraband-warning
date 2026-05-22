/datum/unit_test/contraband_warning_component_visibility

/datum/unit_test/contraband_warning_component_visibility/Run()
	var/obj/item/test_item = allocate(/obj/item/analyzer)
	var/mob/living/carbon/human/consistent/viewer = allocate(__IMPLIED_TYPE__)
	test_item.AddComponent(/datum/component/contraband_warning, "Test level", TRUE, "Test warning.")

	var/list/examine_text = list()
	SEND_SIGNAL(test_item, COMSIG_ATOM_EXAMINE, viewer, examine_text)
	TEST_ASSERT_EQUAL(length(examine_text), 0, "Contraband warning was visible without a security HUD.")

	ADD_TRAIT(viewer, TRAIT_SECURITY_HUD, TRAIT_SOURCE_UNIT_TESTS)
	examine_text = list()
	SEND_SIGNAL(test_item, COMSIG_ATOM_EXAMINE, viewer, examine_text)
	TEST_ASSERT_EQUAL(length(examine_text), 1, "Contraband warning was not visible with a security HUD.")
	TEST_ASSERT(findtext(examine_text[1], "Test level"), "Contraband warning did not include the configured level.")

/datum/unit_test/contraband_warning_component_always_visible

/datum/unit_test/contraband_warning_component_always_visible/Run()
	var/obj/item/test_item = allocate(/obj/item/analyzer)
	var/mob/living/carbon/human/consistent/viewer = allocate(__IMPLIED_TYPE__)
	test_item.AddComponent(/datum/component/contraband_warning, "Public", FALSE, "Public warning.")

	var/list/examine_text = list()
	SEND_SIGNAL(test_item, COMSIG_ATOM_EXAMINE, viewer, examine_text)
	TEST_ASSERT_EQUAL(length(examine_text), 1, "Contraband warning was not visible when HUD gating was disabled.")
	TEST_ASSERT(findtext(examine_text[1], "Public warning."), "Contraband warning did not include the configured warning text.")

/datum/unit_test/contraband_warning_path_rules

/datum/unit_test/contraband_warning_path_rules/Run()
	var/datum/dynamic_contraband_warning_rule/children_rule = new /datum/dynamic_contraband_warning_rule(/obj/item/clothing, TRUE, "Children", TRUE, "Children rule.")
	var/datum/dynamic_contraband_warning_rule/exact_rule = new /datum/dynamic_contraband_warning_rule(/obj/item/clothing, FALSE, "Exact", TRUE, "Exact rule.")
	var/obj/item/clothing/gloves/test_gloves = allocate(__IMPLIED_TYPE__)

	TEST_ASSERT(children_rule.matches(test_gloves), "Children-inclusive rule did not match a subtype.")
	TEST_ASSERT(!exact_rule.matches(test_gloves), "Exact rule matched a subtype.")
