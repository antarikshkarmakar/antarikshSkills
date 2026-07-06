import os
import json
import re
import sys


class DuplicateKeyError(ValueError):
    pass


def no_duplicate_object_pairs(pairs):
    obj = {}
    for key, value in pairs:
        if key in obj:
            raise DuplicateKeyError(key)
        obj[key] = value
    return obj


def load_json_no_duplicates(path, errors, root):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f, object_pairs_hook=no_duplicate_object_pairs)
    except DuplicateKeyError as exc:
        errors.append(f"{os.path.relpath(path, root)} has duplicate JSON key '{exc.args[0]}'")
        return {}


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    skills_dir = os.path.join(root, "skills")

    # 1. Get all modular skill folder names
    skill_folders = [d for d in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, d))]
    print(f"Found {len(skill_folders)} modular skill folders: {', '.join(skill_folders)}")

    errors = []

    # Load package.json
    package_json_path = os.path.join(root, "package.json")
    package_data = load_json_no_duplicates(package_json_path, errors, root)
    package_skills = package_data.get("skills", {})

    # Load .claude-plugin/plugin.json
    # Claude Code auto-discovers this repo's default skills/ directory by folder
    # name. Claude does support an optional "skills" path field for custom skill
    # directories, but the old npm-style array of {"name", "path"} objects is
    # invalid and must not be reintroduced here.
    claude_plugin_json_path = os.path.join(root, ".claude-plugin", "plugin.json")
    claude_plugin_data = load_json_no_duplicates(claude_plugin_json_path, errors, root)
    claude_author = claude_plugin_data.get("author")
    claude_repository = claude_plugin_data.get("repository")
    if not isinstance(claude_author, dict) or not claude_author.get("name"):
        errors.append(".claude-plugin/plugin.json 'author' must be an object with at least a 'name' field")
    if not isinstance(claude_repository, str):
        errors.append(".claude-plugin/plugin.json 'repository' must be a plain string URL")
    if "skills" in claude_plugin_data:
        errors.append(".claude-plugin/plugin.json should omit 'skills' for this default-layout plugin; Claude Code auto-discovers skills/<name>/SKILL.md, and per-skill object arrays are invalid")

    # Load .claude-plugin/marketplace.json
    claude_marketplace_json_path = os.path.join(root, ".claude-plugin", "marketplace.json")
    claude_marketplace_data = load_json_no_duplicates(claude_marketplace_json_path, errors, root)

    # Load .codex-plugin/plugin.json
    codex_plugin_json_path = os.path.join(root, ".codex-plugin", "plugin.json")
    codex_plugin_data = load_json_no_duplicates(codex_plugin_json_path, errors, root)

    # Load Codex repo marketplace metadata
    codex_marketplace_path = os.path.join(root, ".agents", "plugins", "marketplace.json")
    codex_marketplace_data = load_json_no_duplicates(codex_marketplace_path, errors, root)

    # Load skills.sh repo page grouping metadata
    skills_sh_path = os.path.join(root, "skills.sh.json")
    skills_sh_data = load_json_no_duplicates(skills_sh_path, errors, root)

    # Load README.md
    readme_path = os.path.join(root, "README.md")
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()

    public_repo_url = "https://github.com/antarikshkarmakar/antarikshSkills"
    stale_public_strings = (
        "github.com/antarikshSkills",
        "<github-username>/antarikshSkills",
        "github.com/<github-username>/antarikshSkills",
    )
    public_files_to_check = []

    # Load templates/RULESET.md
    ruleset_path = os.path.join(root, "templates", "RULESET.md")
    with open(ruleset_path, "r", encoding="utf-8") as f:
        ruleset_content = f.read()

    skill_observations_template = os.path.join(root, "templates", "skill-observations.md")
    if not os.path.isfile(skill_observations_template):
        errors.append("templates/skill-observations.md is missing")
    else:
        with open(skill_observations_template, "r", encoding="utf-8") as f:
            skill_observations_content = f.read()
        for required_text in ("Suggested improvement", "Principle", "public-safe", "internal", "memory/skill-observations.archive.md"):
            if required_text not in skill_observations_content:
                errors.append(f"templates/skill-observations.md is missing '{required_text}'")

    compact_skill_path = os.path.join(skills_dir, "compact", "SKILL.md")
    with open(compact_skill_path, "r", encoding="utf-8") as f:
        compact_skill_content = f.read()

    skillset_skill_path = os.path.join(skills_dir, "skillset", "SKILL.md")
    with open(skillset_skill_path, "r", encoding="utf-8") as f:
        skillset_skill_content = f.read()

    for label, content in (("README.md", readme_content), ("templates/RULESET.md", ruleset_content)):
        if "memory/skill-observations.md" not in content:
            errors.append(f"{label} is missing reference to 'memory/skill-observations.md'")

    expected_claude_native_name = f"/{claude_plugin_data.get('name')}:align"
    required_readme_notes = (
        expected_claude_native_name,
        "Native Claude Code plugin installs do not expose `/ak-align` aliases",
        "native plugin runtime context comes from the packaged skills under `skills/`",
        "codex plugin add antariksh-skills@antariksh-skills",
        "unexpected argument 'marketplace'",
        "npx skills add antarikshkarmakar/antarikshSkills --full-depth --skill '*'",
        "Advanced Bundle",
    )
    for required_text in required_readme_notes:
        if required_text not in readme_content:
            errors.append(f"README.md is missing plugin install/namespace note '{required_text}'")
    stale_claude_master_claim = "This registers the master `antariksh-unified-skill` and the 21 modular command skills globally inside your Claude Code"
    if stale_claude_master_claim in readme_content:
        errors.append("README.md must not claim the native Claude plugin registers the root master SKILL.md")

    for label, content in (
        ("README.md", readme_content),
        ("templates/RULESET.md", ruleset_content),
        ("skills/compact/SKILL.md", compact_skill_content),
        ("skills/skillset/SKILL.md", skillset_skill_content),
    ):
        if "memory/skill-observations.archive.md" not in content:
            errors.append(f"{label} is missing reference to 'memory/skill-observations.archive.md'")

    # Check all modular skills
    for folder in skill_folders:
        skill_name = f"ak-{folder}"
        expected_path = f"skills/{folder}/SKILL.md"

        # A. check package.json
        if skill_name not in package_skills:
            errors.append(f"package.json is missing skill '{skill_name}'")
        elif package_skills[skill_name] != expected_path:
            errors.append(f"package.json has incorrect path for '{skill_name}': expected '{expected_path}', got '{package_skills[skill_name]}'")

        # C. check SKILL.md frontmatter name
        skill_file_path = os.path.join(skills_dir, folder, "SKILL.md")
        if not os.path.isfile(skill_file_path):
            errors.append(f"Missing SKILL.md file at '{expected_path}'")
        else:
            with open(skill_file_path, "r", encoding="utf-8") as f:
                skill_content = f.read()
            # check name in frontmatter
            name_match = re.search(r"(?m)^name:\s*(\S+)", skill_content)
            if not name_match:
                errors.append(f"SKILL.md at '{expected_path}' is missing 'name' in frontmatter")
            elif name_match.group(1) != skill_name:
                errors.append(f"SKILL.md at '{expected_path}' has incorrect frontmatter name: expected '{skill_name}', got '{name_match.group(1)}'")

        # D. check README.md command table
        readme_search_str = f"skills/{folder}/SKILL.md"
        if readme_search_str not in readme_content:
            errors.append(f"README.md is missing reference to '{readme_search_str}' in command table")

        # E. check templates/RULESET.md command table
        ruleset_search_str = f".agents/skills/{folder}/SKILL.md"
        if ruleset_search_str not in ruleset_content:
            errors.append(f"templates/RULESET.md is missing reference to '{ruleset_search_str}' in command table")

    # Also verify that no extra skills are declared in package.json/plugin.json
    for key, path in package_skills.items():
        if key == "antariksh-unified-skill":
            if path != "SKILL.md":
                errors.append(f"package.json 'antariksh-unified-skill' has incorrect path: {path}")
            continue
        folder_name = key[3:] if key.startswith("ak-") else key
        if folder_name not in skill_folders:
            errors.append(f"package.json declares skill '{key}', but folder 'skills/{folder_name}' does not exist")

    # Verify skills.sh repo-page grouping metadata
    if skills_sh_data.get("$schema") != "https://skills.sh/schemas/skills.sh.schema.json":
        errors.append("skills.sh.json must declare the skills.sh schema URL")
    if skills_sh_data.get("notGrouped") != "bottom":
        errors.append("skills.sh.json notGrouped must be 'bottom'")
    groupings = skills_sh_data.get("groupings", [])
    if not isinstance(groupings, list) or not groupings:
        errors.append("skills.sh.json must contain at least one grouping")
    else:
        grouped_skills = []
        for group in groupings:
            title = group.get("title") if isinstance(group, dict) else None
            skills = group.get("skills") if isinstance(group, dict) else None
            if not title:
                errors.append("skills.sh.json contains a grouping without a title")
            if not isinstance(skills, list) or not skills:
                errors.append(f"skills.sh.json grouping '{title or '<missing>'}' must list at least one skill")
                continue
            grouped_skills.extend(skills)

        expected_skills_sh_names = {f"ak-{folder}" for folder in skill_folders}
        expected_skills_sh_names.add("antariksh-unified-skill")
        grouped_skill_set = set(grouped_skills)
        missing_grouped = sorted(expected_skills_sh_names - grouped_skill_set)
        extra_grouped = sorted(grouped_skill_set - expected_skills_sh_names)
        for name in missing_grouped:
            errors.append(f"skills.sh.json is missing skill '{name}'")
        for name in extra_grouped:
            errors.append(f"skills.sh.json references unknown skill '{name}'")
        for name in sorted({name for name in grouped_skills if grouped_skills.count(name) > 1}):
            errors.append(f"skills.sh.json lists skill '{name}' more than once")
        advanced = next((group for group in groupings if isinstance(group, dict) and group.get("title") == "Advanced Bundle"), None)
        if not advanced or "antariksh-unified-skill" not in advanced.get("skills", []):
            errors.append("skills.sh.json must group 'antariksh-unified-skill' under 'Advanced Bundle'")

    # Verify Codex-native plugin metadata
    expected_codex_name = package_data.get("name")
    if claude_plugin_data.get("name") != expected_codex_name:
        errors.append(f".claude-plugin/plugin.json name must match package.json name '{expected_codex_name}'")
    if claude_plugin_data.get("version") != package_data.get("version"):
        errors.append(".claude-plugin/plugin.json version must match package.json version")
    if package_data.get("repository", {}).get("url") != f"git+{public_repo_url}.git":
        errors.append("package.json repository.url must point to the public repository")
    if package_data.get("bugs", {}).get("url") != f"{public_repo_url}/issues":
        errors.append("package.json bugs.url must point to the public repository issues")
    if package_data.get("homepage") != f"{public_repo_url}#readme":
        errors.append("package.json homepage must point to the public README")

    if claude_plugin_data.get("homepage") != f"{public_repo_url}#readme":
        errors.append(".claude-plugin/plugin.json homepage must point to the public README")
    if claude_plugin_data.get("repository") != public_repo_url:
        errors.append(".claude-plugin/plugin.json repository must be the plain string URL of the public repository")

    # Verify SECURITY.md exists with reporting contact and accepted-findings table
    security_path = os.path.join(root, "SECURITY.md")
    if not os.path.isfile(security_path):
        errors.append("Missing SECURITY.md file in repository root")
    else:
        with open(security_path, "r", encoding="utf-8") as f:
            security_content = f.read()
        for required_text in ("Reporting a Vulnerability", "Known & Accepted Audit Findings", "antariksh.karmakar@gmail.com"):
            if required_text not in security_content:
                errors.append(f"SECURITY.md is missing '{required_text}'")

    # Verify LICENSE file exists and has correct copyright details
    license_path = os.path.join(root, "LICENSE")
    if not os.path.isfile(license_path):
        errors.append("Missing LICENSE file in repository root")
    else:
        with open(license_path, "r", encoding="utf-8") as f:
            license_content = f.read()
        if "Copyright (c) 2026 Antariksh Karmakar <antariksh.karmakar@gmail.com>" not in license_content:
            errors.append("LICENSE file is missing copyright attribution for Antariksh Karmakar")
        if "MIT License" not in license_content:
            errors.append("LICENSE is not an MIT License")

    # Verify Claude plugin license
    if claude_plugin_data.get("license") != "MIT":
        errors.append(".claude-plugin/plugin.json is missing 'license': 'MIT'")

    # Verify Claude marketplace metadata
    owner_info = claude_marketplace_data.get("owner", {})
    if owner_info.get("name") != "Antariksh Karmakar":
        errors.append(".claude-plugin/marketplace.json owner name must be 'Antariksh Karmakar'")
    if owner_info.get("email") != "antariksh.karmakar@gmail.com":
        errors.append(".claude-plugin/marketplace.json owner email must be 'antariksh.karmakar@gmail.com'")

    public_files_to_check.extend((
        ("README.md", readme_content),
        ("package.json", json.dumps(package_data)),
        (".claude-plugin/plugin.json", json.dumps(claude_plugin_data)),
        (".claude-plugin/marketplace.json", json.dumps(claude_marketplace_data)),
        (".codex-plugin/plugin.json", json.dumps(codex_plugin_data)),
        ("skills.sh.json", json.dumps(skills_sh_data)),
    ))
    for label, content in public_files_to_check:
        for stale_text in stale_public_strings:
            if stale_text in content:
                errors.append(f"{label} contains stale public repository placeholder '{stale_text}'")

    if codex_plugin_data.get("name") != expected_codex_name:
        errors.append(f".codex-plugin/plugin.json name must match package.json name '{expected_codex_name}'")
    if codex_plugin_data.get("version") != package_data.get("version"):
        errors.append(".codex-plugin/plugin.json version must match package.json version")
    if codex_plugin_data.get("skills") != "./skills/":
        errors.append(".codex-plugin/plugin.json must expose skills via './skills/'")

    codex_interface = codex_plugin_data.get("interface", {})
    for key in ("displayName", "shortDescription", "longDescription", "developerName", "category", "capabilities", "defaultPrompt"):
        if key not in codex_interface:
            errors.append(f".codex-plugin/plugin.json interface is missing '{key}'")

    marketplace_plugins = codex_marketplace_data.get("plugins", [])
    marketplace_match = next((p for p in marketplace_plugins if p.get("name") == expected_codex_name), None)
    if not marketplace_match:
        errors.append(f".agents/plugins/marketplace.json is missing plugin '{expected_codex_name}'")
    else:
        source = marketplace_match.get("source", {})
        policy = marketplace_match.get("policy", {})
        if source.get("source") != "local":
            errors.append(".agents/plugins/marketplace.json source.source must be 'local'")
        if source.get("path") != "./":
            errors.append(".agents/plugins/marketplace.json source.path must be './' for this repo-root plugin")
        if policy.get("installation") != "AVAILABLE":
            errors.append(".agents/plugins/marketplace.json policy.installation must be 'AVAILABLE'")
        if policy.get("authentication") != "ON_INSTALL":
            errors.append(".agents/plugins/marketplace.json policy.authentication must be 'ON_INSTALL'")
        if marketplace_match.get("category") != "Productivity":
            errors.append(".agents/plugins/marketplace.json category must be 'Productivity'")

    if errors:
        print("\nManifest parity checks FAILED with the following errors:")
        for err in errors:
            print(f" - {err}")
        sys.exit(1)
    else:
        print("\nManifest parity checks PASSED successfully! package.json, Claude/Codex plugin metadata, skill files, README, and RULESET are in sync.")
        sys.exit(0)

if __name__ == "__main__":
    main()
