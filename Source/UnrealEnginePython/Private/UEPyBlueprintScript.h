#pragma once

#include "UEPyModule.h"

PyObject* py_unreal_engine_register_blueprint_script(PyObject*, PyObject*);
PyObject* py_unreal_engine_unregister_all_blueprint_scripts(PyObject*, PyObject*);
PyObject* py_unreal_engine_get_registered_blueprint_scripts(PyObject*, PyObject*);
PyObject* py_unreal_engine_call_function_by_class(PyObject*, PyObject*);
PyObject* py_unreal_engine_describe_function(PyObject*, PyObject*);
void unreal_engine_python_unregister_all_blueprint_scripts();
