#!/usr/bin/env python3

# Copyright 2019 Stanford University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import argparse
import collections
import csv
import os
import sys

import chart_util as util

class Parser(util.Parser):
    def __init__(self, ngraphs, dependence, nodes, system, machine, resource, threshold, csv_dialect):
        self.ngraphs = ngraphs
        self.dependence = dependence.replace('_', ' ')
        self.nodes = nodes
        self.system = system
        self.machine = machine
        self.resource = resource
        self.threshold = threshold
        self.csv_dialect = csv_dialect

        self.header = []
        self.table = collections.defaultdict(lambda: collections.defaultdict(lambda: float('inf')))
        self.metg = collections.defaultdict(lambda: float('inf'))

    def filter(self, row):
        return row['ngraphs'] == self.ngraphs and row['type'] == self.dependence and row['nodes'] == self.nodes and (not self.system or row['name'] == self.system)

    def process(self, row, data, metg=None):
        if row['name'] not in self.header:
            self.header.append(row['name'])

        for values in zip(*list(data.values())):
            items = dict(zip(data.keys(), values))

            self.table[items['iterations']][row['name']] = min(
                items['%s_per_second' % self.resource],
                self.table[items['iterations']][row['name']],
                key=float)

            self.metg[items['iterations']] = min(
                util.get_machine_parameters(self.machine, self.resource)['peak_%s' % self.resource] * self.threshold,
                self.metg[items['iterations']],
                key=float)

    def error_value(self):
        return {}

    def complete(self):
        # FIXME: This isn't actually the criteria we'd like to sort on,
        # we'd prefer to sort so that the list of names roughly parallels
        # the order of the bars in the graph.
        self.header.sort()
        self.header.insert(0, 'iterations')
        self.header.append('metg')

        out = csv.DictWriter(sys.stdout, self.header, dialect=self.csv_dialect)
        out.writeheader()
        for iterations in sorted(self.table.keys()):
            row = self.table[iterations]
            row = {k: None if v == float('inf') else v for k, v in row.items()}
            row['iterations'] = iterations
            row['metg'] = self.metg[iterations]
            out.writerow(row)

def driver(ngraphs, dependence, nodes, system, machine, resource, threshold, csv_dialect, verbose):
    parser = Parser(ngraphs, dependence, nodes, system, machine, resource, threshold, csv_dialect)
    parser.parse(machine, resource, threshold, False, verbose)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-g', '--ngraphs', type=int, required=True)
    parser.add_argument('-d', '--dependence', required=True)
    parser.add_argument('-n', '--nodes', type=int, required=True)
    parser.add_argument('-s', '--system')
    parser.add_argument('-m', '--machine', required=True)
    parser.add_argument('-r', '--resource', default='flops')
    parser.add_argument('-t', '--threshold', type=float, default=0.5)
    parser.add_argument('--csv-dialect', default='excel-tab')
    parser.add_argument('-v', '--verbose', action='store_true')
    args = parser.parse_args()
    driver(**vars(args))
