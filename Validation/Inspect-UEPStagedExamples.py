"""Check staged syntax/eager imports, reporting deferred feature dependencies."""
import argparse
import ast
import json
from pathlib import Path
import subprocess


def inspect(repo):
    def git(*args):
        return subprocess.check_output(["git", "-C", str(repo), *args], text=True, encoding="utf-8")
    indexed = set(git("ls-files").splitlines())
    staged = git("diff", "--cached", "--name-only", "--diff-filter=ACMR").splitlines()
    modules, roots = {}, []
    for relative in ("UEPLyraIntegration/Overlay/Content/Scripts", "UEPLyraIntegration/Tools", "UEPLyraIntegration/Tests"):
        root = repo / relative; roots.append(root)
        for file in root.rglob("*.py"):
            parts = list(file.relative_to(root).with_suffix("").parts)
            if parts[-1] == "__init__": parts.pop()
            if parts: modules[".".join(parts)] = file.relative_to(repo).as_posix()
    missing, deferred, parsed = [], [], 0
    for name in staged:
        if not name.endswith(".py"): continue
        source = git("show", ":" + name)
        tree = ast.parse(source, filename=name); parsed += 1
        file = repo / name
        root = next((root for root in roots if file.is_relative_to(root)), None)
        if root is None: continue
        parts = list(file.relative_to(root).with_suffix("").parts)
        package = parts[:-1]
        if parts[-1] == "__init__": package = parts[:-1]
        parents = {child: parent for parent in ast.walk(tree) for child in ast.iter_child_nodes(parent)}
        for node in ast.walk(tree):
            imports = []
            cursor, lazy = node, False
            while cursor in parents:
                cursor = parents[cursor]
                lazy |= isinstance(cursor, (ast.FunctionDef, ast.AsyncFunctionDef, ast.If, ast.Try))
            if isinstance(node, ast.Import): imports.extend(value.name for value in node.names)
            elif isinstance(node, ast.ImportFrom):
                base = package[:len(package) - node.level + 1] if node.level else []
                if node.module: base += node.module.split(".")
                if base: imports.append(".".join(base))
                imports.extend(".".join(base + [value.name]) for value in node.names if value.name != "*")
            for module in imports:
                target = modules.get(module)
                if target is not None and target not in indexed:
                    (deferred if lazy else missing).append(dict(source=name, module=module, missing_index_path=target))
    return dict(status="failed" if missing else "passed", staged_python_files=parsed, missing_local_imports=missing,
                deferred_feature_imports=deferred, deferred_paths_require_isolated_batch_tests=True,
                dynamic_asset_profile_dependencies_checked=False, native_runtime_acceptance=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--repo", required=True)
    result = inspect(Path(parser.parse_args().repo).resolve())
    print(json.dumps(result, ensure_ascii=False))
    raise SystemExit(1 if result["status"] != "passed" else 0)
