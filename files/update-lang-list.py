#!/usr/bin/env python

import pprint
import os

from django.conf.locale import LANG_INFO
from django.utils import translation


def get_django_lang_name(code, all_codes):
    code = code.lower().replace('_', '-')
    code_orig = code
    lang_info = LANG_INFO.get(code)
    if not lang_info:
        code = code.split('-', 1)[0]
        if code not in all_codes:
            lang_info = LANG_INFO.get(code)
    if lang_info:
        return code, lang_info['name']
    else:
        return code_orig, code_orig


HORIZON_DIR = '/opt/stack/horizon'

langs_horizon = os.listdir(os.path.join(HORIZON_DIR, 'horizon', 'locale'))
langs_dashboard = os.listdir(os.path.join(HORIZON_DIR, 'openstack_dashboard', 'locale'))
# Pick up languages with both horizon and openstack_dashboard translations
langs = set(langs_horizon) & set(langs_dashboard)

lang_list = [get_django_lang_name(l, langs) for l in sorted(langs)]
print 'LANGUAGES = ',
pprint.pprint(tuple(lang_list))
