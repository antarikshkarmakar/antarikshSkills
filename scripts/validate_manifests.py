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
    claude_plugin_json_path = os.path.join(root, ".claude-plugin", "plugin.json")
    claude_plugin_data = load_json_no_duplicates(claude_plugin_json_path, errors, root)
    claude_plugin_skills = claude_plugin_data.get("skills", [])
    claude_plugin_skill_names = [item.get("name") for item in claude_plugin_skills if item.get("name")]
    for name in sorted({name for name in claude_plugin_skill_names if claude_plugin_skill_names.count(name) > 1}):
        errors.append(f".claude-plugin/plugin.json declares duplicate skill name '{name}'")

    # Load .codex-plugin/plugin.json
    codex_plugin_json_path = os.path.join(root, ".codex-plugin", "plugin.json")
    codex_plugin_data = load_json_no_duplicates(codex_plugin_json_path, errors, root)

    # Load Codex repo marketplace metadata
    codex_marketplace_path = os.path.join(root, ".agents", "plugins", "marketplace.json")
    codex_marketplace_data = load_json_no_duplicates(codex_marketplace_path, errors, root)

    # Load README.md
    readme_path = os.path.join(root, "README.md")
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()

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

        # B. check Claude plugin.json
        plugin_match = next((s for s in claude_plugin_skills if s.get("name") == skill_name), None)
        if not plugin_match:
            errors.append(f".claude-plugin/plugin.json is missing skill '{skill_name}'")
        elif plugin_match.get("path") != expected_path:
            errors.append(f".claude-plugin/plugin.json has incorrect path for '{skill_name}': expected '{expected_path}', got '{plugin_match.get('path')}'")

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

    for item in claude_plugin_skills:
        name = item.get("name")
        path = item.get("path")
        if name == "antariksh-unified-skill":
            if path != "SKILL.md":
                errors.append(f".claude-plugin/plugin.json 'antariksh-unified-skill' has incorrect path: {path}")
            continue
        folder_name = name[3:] if name.startswith("ak-") else name
        if folder_name not in skill_folders:
            errors.append(f".claude-plugin/plugin.json declares skill '{name}', but folder 'skills/{folder_name}' does not exist")

    # Verify Codex-native plugin metadata
    expected_codex_name = package_data.get("name")
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
