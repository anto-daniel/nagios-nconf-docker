#!/usr/bin/env python
"""Copyright 2014 Cyrus Dasadia

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This is a helper script to help integrate monitoring systems with CitoEngine.

For more information, refer to http://citoengine.readthedocs.org/

May the force be with you!
"""
import sys
import re
import csv
try:
    from argparse import ArgumentParser
except ImportError:
    print 'Please run "pip install argparse"'
    sys.exit(1)


def parse_arguments():
    options = dict()
    args = ArgumentParser()
    args.add_argument('--config-file', '-c', help='Monitoring service\'s config file', required=True, dest='cfg_file')
    args.add_argument('--type', '-t', help='Config type', choices=['nagios', 'sensu'], required=True, dest='config_type')
    args.add_argument('--debug', help='Debug mode', required=False, action='store_true', dest='debug')
    args.add_argument('--events-file', '-e', help='Events csv file', required=False, dest='events_file')
    args.add_argument('--out', '-o', help='Save output to a file', required=False, default='stdout', dest='out_file')
    xgroup = args.add_mutually_exclusive_group(required=True)
    xgroup.add_argument('--parse', '-p', help='Parse config and display the output', action='store_true', dest='parse')
    xgroup.add_argument('--generate', '-g', help='Generate config and display the output', action='store_true', dest='generate')
    options = args.parse_args()
    return options


class CitoConfigParser(object):
    def __init__(self, *args, **kwargs):
        self.cfg_file = kwargs['cfg_file']
        self.service_defs = dict()
        self.config_type = kwargs['config_type']
        if 'debug' in kwargs:
            self.debug = True
        else:
            self.debug = False
        if self.config_type == 'nagios':
            self.pattern = r'service_description\s+([\w\-\s]+)\b'
        else:
            raise ValueError('Config type %s does not have a valid pattern' % self.config_type)
        self.events_def = dict()
        if kwargs['out_file'] != 'stdout':
            self.output = open(kwargs['out_file'], 'w')
        else:
            self.output = None

    def grep_pattern(self, line):
        match = re.compile(self.pattern).search(line)
        if match:
            svc = match.groups()[0]
            return svc
        else:
            return None

    def output_writer(self, line):
        if self.output:
            self.output.write(line + '\n')
        else:
            print line

    def parse_config_file(self):
        for line_num, line in enumerate(open(self.cfg_file)):
            svc = self.grep_pattern(line)
            if svc:
                if svc in self.service_defs:
                    if self.debug:
                        print  "Duplicate Service: %s at line %s and %s" % (svc, self.service_defs[svc], line_num)
                else:
                    self.service_defs[svc] = line_num

    def parse_events_file(self, events_file):
        with open(events_file) as csv_file:
            csvreader = csv.reader(csv_file)
            for row in csvreader:
                self.events_def[row[6]] = row[0]

    def print_service_deps(self):
        self.parse_config_file()
        for svc in self.service_defs:
            self.output_writer(svc)

    def generate_new_config(self, events_file):
        self.parse_config_file()
        self.parse_events_file(events_file)
        for line in open(self.cfg_file):
            svc = self.grep_pattern(line)
            self.output_writer(line.strip())
            if svc:
                if self.config_type == 'nagios':
                    try:
                        self.output_writer('_CITOEVENTID\t\t\t\t%s' % self.events_def[svc])
                    except KeyError:
                        print "ERROR: Cannot find event_id for service:%s in %s" % (svc, events_file)
                        print "Event defs \n\n%s" %  self.events_def
                        #sys.exit(1)
                        continue
                else:
                    raise ValueError('Cannot generate config for %s config_type, yet.' % self.config_type)

if __name__ == "__main__":
    options = parse_arguments()
    c = CitoConfigParser(cfg_file=options.cfg_file, config_type=options.config_type, out_file=options.out_file)
    if options.parse:
        c.print_service_deps()
    elif options.generate:
        if not options.events_file:
            print 'You need to call this script with --events-file <filename>'
            sys.exit(1)
        else:
            c.generate_new_config(options.events_file)
