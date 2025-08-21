import configparser

def get_waka_config(raw):
    configurator = configparser.ConfigParser()
    configurator.read(raw.replace)
    return {s: dict(configurator.items(s)) for s in configurator.sections()}