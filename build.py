import argparse
import collections
import logging
import os
import re
import shutil
import subprocess
import yaml
import yaml.resolver

environ = os.environ

RECIPE_VARIABLE_BEGIN = '\$\('
RECIPE_VARIABLE_END = '\)'
ENV_VARIABLE_BEGIN = '\$\{'
ENV_VARIABLE_END = '\}'


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('recipe', metavar='RECIPE')
    parser.add_argument('ingredients', metavar='INGREDIENTS')
    parser.add_argument('-l', '--log-format', dest='log_format', default='[%(asctime)s][%(levelname)s] %(message)s')
    return parser.parse_args()


def source(script, update=True, clean=True):
    """
    Source variables from a shell script
    import them in the environment (if update==True)
    and report only the script variables (if clean==True)
    """

    global environ
    if clean:
        environ_back = dict(environ)
        environ.clear()

    pipe = subprocess.Popen(". %s; env" % script, stdout=subprocess.PIPE, shell=True)
    data = pipe.communicate()[0]

    env = dict((line.decode('UTF-8').split("=", 1) for line in data.splitlines()))

    if clean:
        # remove unwanted minimal vars
        env.pop('LINES', None)
        env.pop('COLUMNS', None)
        environ = dict(environ_back)

    if update:
        environ.update(env)

    return env


def load(recipe_file, ingredients_file):
    with open(ingredients_file) as ingredients_in:
        ingredients_yaml = '\n'.join(ingredients_in.readlines())
        ingredients = yaml.load(ingredients_yaml)

    with open(recipe_file) as recipe_in:
        recipe_yaml = '\n'.join(recipe_in.readlines())
        recipe = yaml.load(recipe_yaml)
        ingredients.update(recipe)
        recipe_yaml = replace_variables(recipe_yaml, ingredients)
        recipe = yaml.load(recipe_yaml)
    return recipe


def replace_variables(text_yaml, recipe):
    result = str(text_yaml)
    recipe_variable_definitions = dict(recipe)
    recipe_variable_definitions.pop('targets')
    recipe_variables = []
    for variable_name, variable_value in recipe_variable_definitions.items():
        variable_value = replace_variable(variable_value, recipe_variable_definitions, RECIPE_VARIABLE_BEGIN, RECIPE_VARIABLE_END)
        recipe_variables.append((variable_name, variable_value))

    for variable_name, variable_value in recipe_variables:
        result = re.sub(RECIPE_VARIABLE_BEGIN + variable_name + RECIPE_VARIABLE_END, variable_value, result)
        
    env_variable_definitions = dict(environ)
    env_variables = []
    for variable_name, variable_value in env_variable_definitions.items():
        variable_value = replace_variable(variable_value, env_variable_definitions, ENV_VARIABLE_BEGIN, ENV_VARIABLE_END)
        env_variables.append((variable_name, variable_value))

    for variable_name, variable_value in env_variables:
        result = re.sub(ENV_VARIABLE_BEGIN + variable_name + ENV_VARIABLE_END, variable_value, result)

    return result

def replace_variable(variable_value, variable_definitions, variable_begin, variable_end):
    sub_variables = set(re.findall(variable_begin + '(.+?)' + variable_end, variable_value))
    for sub_variable_name in sub_variables:
        sub_variable_value = variable_definitions[sub_variable_name]
        if re.findall(variable_begin + '(.+?)' + variable_end, sub_variable_value):
            sub_variable_value = replace_variable(sub_variable_value, variable_definitions, variable_begin, variable_end)
        variable_value = re.sub(variable_begin + sub_variable_name + variable_end, sub_variable_value, variable_value)
    return variable_value


def build_all(targets):
    for target, target_recipe in targets.items():
        build_target(target, target_recipe)

def build_target(target, target_recipe):
    if isinstance(target_recipe, dict):
        if 'command' in target_recipe:
            command = parse_command(target_recipe)
            required = parse_required(target_recipe)
            optional = parse_optional(target_recipe)

            with open(target, mode='w') as target_out:
                process_definition = ' '.join(command + required + optional)
                logging.debug('{}: {}'.format(target, process_definition))
                subprocess.run(process_definition, env=environ, shell=True, stdout=target_out)
        else:
            parents = target.split(' ')
            for pattern, pattern_recipe in target_recipe.items():
                pattern_recipe_yaml = yaml.dump(pattern_recipe)
                for parent in parents:
                    child = pattern.replace('$()', parent)
                    child_recipe_yaml = pattern_recipe_yaml.replace('$()', parent)
                    child_recipe = yaml.load(child_recipe_yaml)
                    build_target(child, child_recipe)

    elif isinstance(target_recipe, list):
        for command in target_recipe:
            subprocess.run(command, env=environ, shell=True)
    else:
        command = target_recipe
        subprocess.run(command, env=environ, shell=True)


def parse_command(target_recipe):
    command = target_recipe['command']
    executable = command.split()[0]
    if not os.path.exists(executable) and not shutil.which(executable):
        raise RuntimeError('Command "{}" is invalid'.format(command))
    return [command]


def parse_required(target_recipe):
    result = []
    if 'required' in target_recipe:
        required = target_recipe['required']
        for file in required:
            result.append(file)
    return result


def parse_optional(target_recipe):
    result = []
    if 'optional' in target_recipe:
        optional = target_recipe['optional']
        for file in optional:
            result.append(file)
    return result

def main():
    _mapping_tag = yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG

    def dict_representer(dumper, data):
        return dumper.represent_dict(data.items())

    def dict_constructor(loader, node):
        return collections.OrderedDict(loader.construct_pairs(node))

    yaml.add_representer(collections.OrderedDict, dict_representer)
    yaml.add_constructor(_mapping_tag, dict_constructor)


    args = parse_args()
    logging.basicConfig(format=args.log_format, level=logging.DEBUG)
    source('./path.sh', True, True)
    recipe = load(args.recipe, args.ingredients)
    build_all(recipe['targets'])

if __name__ == '__main__':
    main()
