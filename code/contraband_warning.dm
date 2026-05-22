#define CONTRABAND_WARNING_MODULE_ID "contraband-warning"
#define CONTRABAND_WARNING_CONFIG_PATH ".dynamic_modules_build/generated/dynamic_modules_config.json"
#define CONTRABAND_WARNING_DEFAULT_LEVEL "Syndicate contraband"
#define CONTRABAND_WARNING_DEFAULT_TEXT "Security systems identify this item as contraband."

SUBSYSTEM_DEF(dynamic_contraband_warning)
	name = "Dynamic Contraband Warnings"
	flags = SS_NO_FIRE
	dependencies = list(
		/datum/controller/subsystem/assets,
		/datum/controller/subsystem/traitor,
	)

	var/include_uplink_items = TRUE
	var/include_trait_contraband = FALSE
	var/require_security_hud = TRUE
	var/default_level = CONTRABAND_WARNING_DEFAULT_LEVEL
	var/warning_text = CONTRABAND_WARNING_DEFAULT_TEXT
	var/list/datum/dynamic_contraband_warning_rule/contraband_rules = list()
	var/list/datum/dynamic_contraband_warning_rule/exemption_rules = list()
	var/list/uplink_item_typecache = list()

/datum/controller/subsystem/dynamic_contraband_warning/Initialize()
	load_module_config()
	refresh_uplink_item_typecache()
	RegisterSignal(SSdcs, COMSIG_GLOB_NEW_ITEM, PROC_REF(on_new_item))
	for(var/obj/item/existing_item in world)
		if(!(existing_item.flags_1 & INITIALIZED_1))
			continue
		apply_warning_component(existing_item)
		CHECK_TICK
	return SS_INIT_SUCCESS

/datum/controller/subsystem/dynamic_contraband_warning/Destroy(force)
	UnregisterSignal(SSdcs, COMSIG_GLOB_NEW_ITEM)
	QDEL_LIST(contraband_rules)
	QDEL_LIST(exemption_rules)
	uplink_item_typecache = null
	return ..()

/datum/controller/subsystem/dynamic_contraband_warning/proc/load_module_config()
	var/list/config = dynamic_contraband_warning_read_config()
	if(!islist(config))
		return

	include_uplink_items = dynamic_contraband_warning_bool(config["include_uplink_items"], include_uplink_items)
	include_trait_contraband = dynamic_contraband_warning_bool(config["include_trait_contraband"], include_trait_contraband)
	require_security_hud = dynamic_contraband_warning_bool(config["require_security_hud"], require_security_hud)
	default_level = dynamic_contraband_warning_text(config["default_level"], default_level)
	warning_text = dynamic_contraband_warning_text(config["warning_text"], warning_text)

	QDEL_LIST(contraband_rules)
	QDEL_LIST(exemption_rules)
	contraband_rules = dynamic_contraband_warning_parse_rules(config["contraband"], default_level, require_security_hud, warning_text)
	exemption_rules = dynamic_contraband_warning_parse_rules(config["exemptions"], default_level, require_security_hud, warning_text)

/datum/controller/subsystem/dynamic_contraband_warning/proc/refresh_uplink_item_typecache()
	uplink_item_typecache = list()
	if(!include_uplink_items)
		return

	var/list/uplink_item_paths = list()
	for(var/datum/uplink_item/uplink_item as anything in SStraitor.uplink_items)
		if(!uplink_item.item)
			continue
		if(!(uplink_item.uplink_item_flags & SYNDIE_TRIPS_CONTRABAND))
			continue
		uplink_item_paths |= uplink_item.item

	if(length(uplink_item_paths))
		uplink_item_typecache = typecacheof(uplink_item_paths)

/datum/controller/subsystem/dynamic_contraband_warning/proc/on_new_item(datum/source, obj/item/created_item)
	SIGNAL_HANDLER
	apply_warning_component(created_item)

/datum/controller/subsystem/dynamic_contraband_warning/proc/apply_warning_component(obj/item/target)
	if(!istype(target) || QDELETED(target))
		return
	if(target.GetComponent(/datum/component/contraband_warning))
		return
	if(is_exempted(target))
		return

	var/datum/dynamic_contraband_warning_rule/rule = get_rule_for_item(target)
	if(rule)
		target.AddComponent(/datum/component/contraband_warning, rule.level, rule.require_security_hud, rule.warning_text)
		return

	if(is_default_contraband_item(target))
		target.AddComponent(/datum/component/contraband_warning, default_level, require_security_hud, warning_text)

/datum/controller/subsystem/dynamic_contraband_warning/proc/is_exempted(obj/item/target)
	for(var/datum/dynamic_contraband_warning_rule/exemption as anything in exemption_rules)
		if(exemption.matches(target))
			return TRUE
	return FALSE

/datum/controller/subsystem/dynamic_contraband_warning/proc/get_rule_for_item(obj/item/target)
	for(var/datum/dynamic_contraband_warning_rule/rule as anything in contraband_rules)
		if(rule.matches(target))
			return rule

/datum/controller/subsystem/dynamic_contraband_warning/proc/is_default_contraband_item(obj/item/target)
	if(include_uplink_items && is_type_in_typecache(target, uplink_item_typecache))
		return TRUE

	if(include_trait_contraband && HAS_TRAIT(target, TRAIT_CONTRABAND))
		return TRUE

	return FALSE

/datum/dynamic_contraband_warning_rule
	var/obj/item/path
	var/include_children = TRUE
	var/level = CONTRABAND_WARNING_DEFAULT_LEVEL
	var/require_security_hud = TRUE
	var/warning_text = CONTRABAND_WARNING_DEFAULT_TEXT

/datum/dynamic_contraband_warning_rule/New(obj/item/_path, _include_children = TRUE, _level = CONTRABAND_WARNING_DEFAULT_LEVEL, _require_security_hud = TRUE, _warning_text = CONTRABAND_WARNING_DEFAULT_TEXT)
	path = _path
	include_children = _include_children
	level = _level || CONTRABAND_WARNING_DEFAULT_LEVEL
	require_security_hud = _require_security_hud
	warning_text = _warning_text || CONTRABAND_WARNING_DEFAULT_TEXT

/datum/dynamic_contraband_warning_rule/proc/matches(obj/item/target)
	if(!path || !istype(target))
		return FALSE
	if(include_children)
		return istype(target, path)
	return target.type == path

/datum/component/contraband_warning
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/warning_level = CONTRABAND_WARNING_DEFAULT_LEVEL
	var/require_security_hud = TRUE
	var/warning_text = CONTRABAND_WARNING_DEFAULT_TEXT

/datum/component/contraband_warning/Initialize(_warning_level = CONTRABAND_WARNING_DEFAULT_LEVEL, _require_security_hud = TRUE, _warning_text = CONTRABAND_WARNING_DEFAULT_TEXT)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	warning_level = _warning_level || CONTRABAND_WARNING_DEFAULT_LEVEL
	require_security_hud = _require_security_hud
	warning_text = _warning_text || CONTRABAND_WARNING_DEFAULT_TEXT

/datum/component/contraband_warning/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/contraband_warning/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)

/datum/component/contraband_warning/proc/on_examine(datum/source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if(require_security_hud && !dynamic_contraband_warning_user_can_see(user))
		return

	var/rendered_text = warning_text
	if(warning_level)
		rendered_text = "[rendered_text] Level: [warning_level]."
	examine_text += span_danger("<b>CONTRABAND:</b> [rendered_text]")

/proc/dynamic_contraband_warning_user_can_see(mob/user)
	if(!user)
		return FALSE
	return HAS_TRAIT(user, TRAIT_SECURITY_HUD) || HAS_TRAIT(user, TRAIT_SECURITY_HUD_ID_ONLY)

/proc/dynamic_contraband_warning_read_config()
	var/raw_config = file2text(CONTRABAND_WARNING_CONFIG_PATH)
	if(!raw_config)
		return list()
	var/list/full_config = json_decode(raw_config)
	if(!islist(full_config))
		return list()
	return full_config[CONTRABAND_WARNING_MODULE_ID]?["values"] || list()

/proc/dynamic_contraband_warning_parse_rules(list/raw_rules, fallback_level, fallback_require_security_hud, fallback_warning_text)
	. = list()
	if(!islist(raw_rules))
		return
	for(var/list/raw_rule as anything in raw_rules)
		var/path_text = raw_rule["path"]
		if(!istext(path_text))
			continue
		var/obj/item/item_path = text2path(path_text)
		if(!ispath(item_path, /obj/item))
			continue
		. += new /datum/dynamic_contraband_warning_rule(
			item_path,
			dynamic_contraband_warning_bool(raw_rule["include_children"], TRUE),
			dynamic_contraband_warning_text(raw_rule["level"], fallback_level),
			dynamic_contraband_warning_bool(raw_rule["require_security_hud"], fallback_require_security_hud),
			dynamic_contraband_warning_text(raw_rule["warning_text"], fallback_warning_text),
		)

/proc/dynamic_contraband_warning_bool(value, fallback)
	if(isnull(value))
		return fallback
	return !!value

/proc/dynamic_contraband_warning_text(value, fallback)
	if(!istext(value) || !length(value))
		return fallback
	return value

#undef CONTRABAND_WARNING_MODULE_ID
#undef CONTRABAND_WARNING_CONFIG_PATH
#undef CONTRABAND_WARNING_DEFAULT_LEVEL
#undef CONTRABAND_WARNING_DEFAULT_TEXT
