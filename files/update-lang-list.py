#!/usr/bin/env python
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

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
