let meta = #{
    name: "critic-loop",
    description: "Critic judges Livia's Stable, implementer fixes must-fix items, repeat until SATISFIED",
    when_to_use: "After a build pass: /critic-loop or /workflow critic-loop",
    phases: [
        #{ title: "Critic", detail: "read-only product judgment" },
        #{ title: "Fix", detail: "implementer applies must-fix only" },
    ],
};

let critic_schema = #{
    "type": "object",
    "required": ["verdict", "must_fix"],
    "properties": #{
        "verdict": #{ "type": "string" },
        "must_fix": #{
            "type": "array",
            "maxItems": 12,
            "items": #{
                "type": "object",
                "required": ["id", "issue"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "issue": #{ "type": "string" },
                    "files": #{ "type": "string" },
                },
            },
        },
    },
};

let max_rounds = 3;
let round = 0;
let verdict = "NEEDS_WORK";
let last_report = "";

while round < max_rounds && verdict != "SATISFIED" {
    round += 1;
    phase("Critic");
    log("critic round " + round.to_string());
    let cprompt = "";
    cprompt += "You are the Livia's Stable critic. Read docs/DESIGN.md, docs/ART.md, ";
    cprompt += "scenes/boot/boot.gd, src/farm/farm_yard.gd, scenes/horse/horse_presenter.gd, ";
    cprompt += "src/autoload/economy.gd, tests/run_tests.gd. Run the headless Godot test script ";
    cprompt += "if you can. Do not implement. SATISFIED means the slice is playable, tested, ";
    cprompt += "and honest — not that a bought hero.glb exists. Return verdict SATISFIED or ";
    cprompt += "NEEDS_WORK and a must_fix list of in-repo bugs only.";
    let crit = agent(cprompt, #{
        label: "critic-" + round.to_string(),
        capability_mode: "execute",
        agent_type: "critic",
        output_schema: critic_schema,
    });
    if crit == () || !crit.success || crit.output == () {
        pause("verification", "Critic agent failed; resume to retry or inspect.");
    }
    verdict = crit.output.verdict;
    last_report = json_encode(crit.output);
    log("verdict " + verdict);
    if verdict == "SATISFIED" {
        complete(#{ verdict: verdict, rounds: round, report: last_report });
    }
    let fixes = crit.output.must_fix;
    if fixes == () || fixes.len() == 0 {
        complete(#{ verdict: verdict, rounds: round, report: last_report });
    }
    phase("Fix");
    let fprompt = "";
    fprompt += "Implement ONLY these must-fix critic items in Livia's Stable. ";
    fprompt += "Do not buy assets. Do not expand scope. Re-run headless Godot tests. ";
    fprompt += "Items: " + json_encode(fixes);
    let fix = agent(fprompt, #{
        label: "fix-" + round.to_string(),
        capability_mode: "all",
        agent_type: "general-purpose",
    });
    if fix == () || !fix.success {
        log("implementer failed on round " + round.to_string());
    }
}

complete(#{ verdict: verdict, rounds: round, report: last_report });
