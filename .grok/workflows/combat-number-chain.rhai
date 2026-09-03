let meta = #{
    name: "combat-number-chain",
    description: "Finish the combat number-chain batch: unique-snap holograms, verify five mechanism fixes, run headless smoke",
    when_to_use: "After combat-economy diagnosis, or when smoke fails unique-snap / save / forge / tower upgrade / armor / falloff",
    phases: [
        #{ title: "Diagnose", detail: "unique-snap plus five number-chain checks in parallel" },
        #{ title: "Fix", detail: "unique-snap occupancy if still stacking" },
        #{ title: "Verify", detail: "godot headless smoke_test.gd" },
    ],
};

let status_schema = #{
    "type": "object",
    "required": ["status", "summary"],
    "properties": #{
        "status": #{ "type": "string" },
        "summary": #{ "type": "string" },
        "fix": #{ "type": "string" },
    },
};

let repo = if args == () { "/Volumes/other/IdeaProjects/sirhao/emberline-frontier-07" } else if args.repo == () { "/Volumes/other/IdeaProjects/sirhao/emberline-frontier-07" } else { args.repo };

phase("Diagnose");
let d1 = "";
d1 += "Repo: " + repo + ". READ the code with read_file/grep. Do not edit. ";
d1 += "Check hologram unique-snap: tests/smoke_test.gd ~145-151 spawns two holograms at _cell_center(Vector2i(15,12)). ";
d1 += "scripts/main.gd _unique_paint_cell_center / _hologram_on_paint_cell / _spawn_tower_at. ";
d1 += "Starting TOWER_PADS are holograms. status=broken if two clash holograms can share a paint cell, else ok. ";
d1 += "summary=root cause. fix=smallest patch. Empty status is invalid; you must read the functions.";

let d2 = "";
d2 += "Repo: " + repo + ". READ git diff and the shipped functions. Do not edit. ";
d2 += "Verify these five already-applied fixes still hold: ";
d2 += "1 save shop growth+armor in main.gd _write_run_save/_apply_run_payload and shop.gd restore_growth. ";
d2 += "2 hero.gd melee_strike_damage ranged base is sword damage not cached melee_damage. ";
d2 += "3 tower.gd can_upgrade/upgrade/get_upgrade_cost one contract; main.gd charges after upgrade() succeeds. ";
d2 += "4 main.gd _process_hero_contact calls hurt_hero. ";
d2 += "5 weapon_catalog.gd _gun falloff_range < max_range when falloff_damage < damage. ";
d2 += "status=ok only if all five are present in the file you read; else broken. summary=one line per item.";

let d3 = "";
d3 += "Repo: " + repo + ". READ tests/smoke_test.gd near the end. Do not edit. ";
d3 += "Confirm targeted asserts exist for forge stability, hologram not charged, amplifier upgrade, armor contact, falloff interval, save growth. ";
d3 += "status=ok if those asserts are in the file, broken if missing. summary=list assert messages you found.";

let diagnosed = parallel([
    #{ prompt: d1, label: "diag:unique-snap", capability_mode: "read-only", output_schema: status_schema },
    #{ prompt: d2, label: "diag:five-fixes", capability_mode: "read-only", output_schema: status_schema },
    #{ prompt: d3, label: "diag:smoke-asserts", capability_mode: "read-only", output_schema: status_schema },
]);

let snap_status = "ok";
let snap_fix = "";
if diagnosed[0] != () && diagnosed[0].success && diagnosed[0].output != () && diagnosed[0].output.status != () {
    snap_status = diagnosed[0].output.status;
    if diagnosed[0].output.fix != () {
        snap_fix = diagnosed[0].output.fix;
    }
}

phase("Fix");
if snap_status == "broken" {
    let fp = "";
    fp += "Repo: " + repo + ". Minimal Godot 4.7 edit. Do not refactor main.gd. Do not commit. ";
    fp += "Fix hologram unique-snap so two _spawn_tower_at calls on the same cell land >=50px apart on paint centers. ";
    fp += "Hint from diagnose: " + snap_fix + " ";
    fp += "Touch scripts/main.gd _unique_paint_cell_center / _hologram_on_paint_cell / _spawn_tower_at only as needed. ";
    fp += "Keep pads on _paint_center_of_cell. status=ok after the patch, summary=what changed.";
    let fixed = agent(fp, #{ label: "fix:unique-snap", capability_mode: "read-write", output_schema: status_schema });
    if fixed != () && fixed.success && fixed.output != () && fixed.output.status != () {
        snap_status = fixed.output.status;
    }
} else {
    log("unique-snap diagnose did not report broken; skip write");
}

phase("Verify");
let vp = "";
vp += "Repo: " + repo + ". Run: godot --headless --path . --script tests/smoke_test.gd ";
vp += "from the repo root. Wait for completion. ";
vp += "status=ok only if stdout contains SMOKE TEST PASS. status=broken if SCRIPT ERROR or Assertion failed. ";
vp += "summary=the assertion message or PASS line. Do not change production code unless smoke fails only on unique-snap still stacking — then apply the smallest occupancy fix and re-run once.";
let verified = agent(vp, #{ label: "verify:smoke", capability_mode: "execute", output_schema: status_schema });

let smoke_status = "unverified";
let smoke_summary = "";
if verified != () && verified.success && verified.output != () && verified.output.status != () {
    smoke_status = verified.output.status;
    if verified.output.summary != () {
        smoke_summary = verified.output.summary;
    }
}

let report = "";
report += "# combat-number-chain\n";
report += "unique-snap: " + snap_status + "\n";
report += "smoke: " + smoke_status + "\n";
report += smoke_summary + "\n";
let path = write_scratch_file("report.md", report);
complete(#{ path: path, unique_snap: snap_status, smoke: smoke_status, summary: smoke_summary });
