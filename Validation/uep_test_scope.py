"""Select affected host tests from local imports and literal file dependencies."""
import ast
import fnmatch
from pathlib import Path
import subprocess

ROOTS = ("Demos/UEPLyraIntegration/Overlay/Content/Scripts", "Demos/UEPLyraIntegration/Tools",
    "Demos/UEPLyraIntegration/Tests", "Content/Scripts", "Validation")
TEST_ROOTS = ("Demos/UEPLyraIntegration/Tests", "Validation/Tests")
DOCUMENT_SUFFIXES = {".md", ".txt", ".rst"}


def normalize(path): return str(path).replace("\\", "/").removeprefix("./")


def changed_paths(repo, *, staged=False):
    """Keep the Examples index separate from the parent repository's gitlink."""
    result = set()
    examples_base = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD:Demos"], encoding="utf-8").strip()
    for directory, prefix in ((repo, ""), (repo/"Demos", "Demos/")):
        command = ["git", "-C", str(directory), "diff"]
        if staged: command += ["--cached"]
        if prefix: command += [examples_base]
        elif not staged: command += ["HEAD"]
        output = subprocess.check_output(command+["--name-only", "-z"], encoding="utf-8")
        result.update(prefix+normalize(name) for name in output.split("\0") if name and name != "Demos")
        if not staged:
            output = subprocess.check_output(["git", "-C", str(directory), "ls-files", "--others", "--exclude-standard", "-z"], encoding="utf-8")
            result.update(prefix+normalize(name) for name in output.split("\0") if name)
    return sorted(result)


def sources(repo):
    files = {}
    for relative in ROOTS:
        root = repo/relative
        if not root.exists(): continue
        for path in root.rglob("*.py"):
            if ".nepy" in path.parts: continue
            name = path.relative_to(repo).as_posix()
            parts = list(path.relative_to(root).with_suffix("").parts)
            if parts[-1] == "__init__": parts.pop()
            # Validation/Tests is a distinct package for relative import lookup.
            files[name] = (".".join(parts), path.read_text(encoding="utf-8-sig"))
    return files


def module_for(name):
    for root in ROOTS:
        if name.startswith(root+"/"):
            parts = name[len(root)+1:].removesuffix(".py").split("/")
            if parts[-1] == "__init__": parts.pop()
            return ".".join(parts)
    return ""


def is_test(name):
    return any(name.startswith(root+"/") for root in TEST_ROOTS) and Path(name).name.startswith("test_") and name.endswith(".py")


def plan(repo, changed, *, patterns=(), full=False):
    changed = sorted({normalize(name) for name in changed if ".nepy" not in Path(normalize(name)).parts})
    files = sources(repo); tests = {name for name in files if is_test(name)}
    reasons, dependencies, constants, parse_errors = {}, {}, {}, []
    modules, basenames = {}, {}
    for name, (module, _) in files.items():
        if module: modules.setdefault(module, set()).add(name)
        basenames.setdefault(Path(name).name, set()).add(name)
    # Deleted/renamed modules must still reach consumers of the old import.
    for name in changed:
        if name.endswith(".py") and name not in files:
            module = module_for(name)
            if module: modules.setdefault(module, set()).add(name)
            basenames.setdefault(Path(name).name, set()).add(name)
    for name, (module, source) in files.items():
        dependencies[name] = set(); constants[name] = set()
        try: tree = ast.parse(source, filename=name)
        except SyntaxError:
            if name in changed: raise
            parse_errors.append(name); continue
        package = module.split(".") if name.endswith("/__init__.py") else module.split(".")[:-1]
        imports = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Import): imports.extend(alias.name for alias in node.names)
            elif isinstance(node, ast.ImportFrom):
                base = package[:len(package)-node.level+1] if node.level else []
                if node.module: base += node.module.split(".")
                if base: imports.append(".".join(base))
                imports.extend(".".join(base+[alias.name]) for alias in node.names if alias.name != "*")
            elif isinstance(node, ast.Constant) and isinstance(node.value, str):
                literal = normalize(node.value); constants[name].add(literal)
                if literal in modules: imports.append(literal)
                if literal.endswith(".py"): dependencies[name].update(basenames.get(literal.rsplit("/", 1)[-1], ()))
        for module_name in imports:
            # Include package initializers as well as the most specific module.
            parts = module_name.split(".")
            for length in range(1, len(parts)+1): dependencies[name].update(modules.get(".".join(parts[:length]), ()))
    affected = set(changed)
    for name in changed:
        if name in files: reasons[name] = ["changed file"]
        for consumer, literals in constants.items():
            if any(literal == name or literal.rsplit("/", 1)[-1] == Path(name).name for literal in literals):
                dependencies[consumer].add(name)
    while True:
        added = {name for name, deps in dependencies.items() if name not in affected and deps & affected}
        if not added: break
        for name in added: reasons[name] = ["depends on "+dependency for dependency in sorted(dependencies[name] & affected)]
        affected.update(added)
    selected = tests & affected
    for pattern in patterns:
        matches = {name for name in tests if fnmatch.fnmatchcase(Path(name).name, pattern) or fnmatch.fnmatchcase(name, pattern)}
        if not matches: raise ValueError("Test pattern matched no files: "+pattern)
        for name in matches: reasons.setdefault(name, []).append("explicit pattern "+pattern)
        selected.update(matches)
    if full:
        selected = tests
        for name in tests: reasons.setdefault(name, []).append("explicit full regression")
    relevant = [name for name in changed if Path(name).suffix.lower() not in DOCUMENT_SUFFIXES]
    covered = set(selected)
    while True:
        upstream = {dependency for name in covered for dependency in dependencies.get(name, ())}-covered
        if not upstream: break
        covered.update(upstream)
    unmapped = [name for name in relevant if name not in covered]
    needs_scope = bool(relevant and not selected and not full)
    return dict(mode="full" if full else "incremental", status="scope_required" if needs_scope else "ready",
        changed_files=changed, selected_test_files=sorted(selected), affected_files=sorted(affected & files.keys()),
        selection_reasons={name:reasons.get(name, []) for name in sorted(selected)},
        unmapped_changed_files=unmapped, unparsed_unaffected_files=parse_errors,
        dependency_analysis="local imports including inheritance, literal module names and file references; dynamic dependencies require explicit patterns/native lanes",
        full_regression_requested=bool(full))
