#!/usr/bin/env python
#
# Copyright (c) 2017 CERN
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# Author:
#    Arne Wiebalck <Arne.Wiebalck@cern.ch>

import argparse
import sys
import ConfigParser
import datetime

from prettytable import PrettyTable
from sqlalchemy import and_
from sqlalchemy import delete
from sqlalchemy import func
from sqlalchemy import MetaData
from sqlalchemy import select
from sqlalchemy import Table
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql.expression import false
from sqlalchemy.ext.declarative import declarative_base


def get_projects(meta):

    """Return a list of all projects in the database"""

    projects = []
    volumes_t = Table('volumes', meta, autoload=True)
    volumes_q = select(columns=[volumes_t.c.project_id,
                                func.count()],
                       whereclause=and_(volumes_t.c.deleted == false()),
                       group_by=volumes_t.c.project_id)
    for (project, _) in volumes_q.execute():
        projects.append(project)

    return projects


def yn_choice():

    """Return True/False after checking with the user"""

    yes = set(['yes', 'y', 'ye'])
    no = set(['no', 'n'])

    print "Do you want to sync? [Yes/No]"
    while True:
        choice = raw_input().lower()
        if choice in yes:
            return True
        elif choice in no:
            return False
        else:
            sys.stdout.write("Do you want to sync? [Yes/No/Abort]")


def sync_quota_usages_project(meta, project_id, quota_usages_to_sync):

    """Sync the quota usages of a project from real usages"""

    print "Syncing %s" % (project_id)
    now = datetime.datetime.utcnow()
    quota_usages_t = Table('quota_usages', meta, autoload=True)
    for resource, quota in quota_usages_to_sync.iteritems():
        quota_usages_t.update().where(
            and_(quota_usages_t.c.project_id == project_id,
                 quota_usages_t.c.resource == resource)).values(
            updated_at=now, in_use=quota).execute()


def get_snapshot_usages_project(meta, project_id):

    """Return the snapshot resource usages of a project"""

    snapshots_t = Table('snapshots', meta, autoload=True)
    snapshots_q = select(columns=[snapshots_t.c.id,
                                  snapshots_t.c.volume_size,
                                  snapshots_t.c.volume_type_id],
                         whereclause=and_(
                         snapshots_t.c.deleted == false(),
                         snapshots_t.c.project_id == project_id))
    return snapshots_q.execute()


def get_volume_usages_project(meta, project_id):

    """Return the volume resource usages of a project"""

    volumes_t = Table('volumes', meta, autoload=True)
    volumes_q = select(columns=[volumes_t.c.id,
                                volumes_t.c.size,
                                volumes_t.c.volume_type_id],
                       whereclause=and_(volumes_t.c.deleted == false(),
                                        volumes_t.c.project_id == project_id))
    return volumes_q.execute()


def get_quota_usages_project(meta, project_id):

    """Return the quota usages of a project"""

    quota_usages_t = Table('quota_usages', meta, autoload=True)
    quota_usages_q = select(columns=[quota_usages_t.c.resource,
                                     quota_usages_t.c.in_use],
                            whereclause=and_(quota_usages_t.c.deleted == false(),
                                             quota_usages_t.c.project_id ==
                                             project_id))
    return quota_usages_q.execute()


def get_resource_types(meta, project_id):

    """Return a list of all resource types"""

    types = []
    quota_usages_t = Table('quota_usages', meta, autoload=True)
    resource_types_q = select(columns=[quota_usages_t.c.resource,
                                       func.count()],
                              whereclause=quota_usages_t.c.deleted == false(),
                              group_by=quota_usages_t.c.resource)
    for (resource, _) in resource_types_q.execute():
        types.append(resource)
    return types


def get_volume_types(meta, project_id):

    """Return a dict with volume type id to name mapping"""

    types = {}
    volume_types_t = Table('volume_types', meta, autoload=True)
    volume_types_q = select(columns=[volume_types_t.c.id,
                                     volume_types_t.c.name],
                            whereclause=volume_types_t.c.deleted == false())
    for (id, name) in volume_types_q.execute():
        types[id] = name
    return types


def makeConnection(db_url):

    """Establish a database connection and return the handle"""

    engine = create_engine(db_url)
    engine.connect()
    Session = sessionmaker(bind=engine)
    thisSession = Session()
    metadata = MetaData()
    metadata.bind = engine
    Base = declarative_base()
    tpl = thisSession, metadata, Base
    return tpl


def get_db_url(config_file):

    """Return the database connection string from the config file"""

    parser = ConfigParser.SafeConfigParser()
    try:
        parser.read(config_file)
        db_url = parser.get('database', 'connection')
    except:
        print "ERROR: Check Cinder configuration file."
        sys.exit(2)
    return db_url


def parse_cmdline_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config",
                        default='./cinder.conf',
                        help='configuration file')
    parser.add_argument("--nosync",
                        action="store_true",
                        help="never sync resources (no interactive check)")
    parser.add_argument("--sync",
                        action="store_true",
                        help="always sync resources (no interactive check)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--list_projects",
                       action="store_true",
                       help='get a list of all projects in the database')
    group.add_argument("--project_id",
                       type=str,
                       help="project to check")
    return parser.parse_args()


def main():
    try:
        args = parse_cmdline_args()
    except Exception as e:
        sys.stdout.write("Check command line arguments (%s)" % e.strerror)

    # connect to the DB
    db_url = get_db_url(args.config)
    cinder_session, cinder_metadata, cinder_Base = makeConnection(db_url)

    # get the volume types
    volume_types = get_volume_types(cinder_metadata,
                                    args.project_id)

    # get the resource types
    resource_types = get_resource_types(cinder_metadata,
                                        args.project_id)

    # check/sync all projects found in the database
    #
    if args.list_projects:
        for p in get_projects(cinder_metadata):
            print p
        sys.exit(0)

    # check a single project
    #
    print "Checking " + args.project_id + " ..."

    # get the quota usage of a project
    quota_usages = {}
    for (resource, count) in get_quota_usages_project(cinder_metadata,
                                                      args.project_id):
        quota_usages[resource] = count

    # get the real usage of a project
    real_usages = {}
    for resource in resource_types:
        real_usages[resource] = 0
    for (_, size, type_id) in get_volume_usages_project(cinder_metadata,
                                                        args.project_id):
        real_usages["volumes"] += 1
        real_usages["volumes_" + volume_types[type_id]] += 1
        real_usages["gigabytes"] += size
        real_usages["gigabytes_" + volume_types[type_id]] += size
    for (_, size, type_id) in get_snapshot_usages_project(cinder_metadata,
                                                          args.project_id):
        real_usages["snapshots"] += 1
        real_usages["snapshots_" + volume_types[type_id]] += 1
        real_usages["gigabytes"] += size
        real_usages["gigabytes_" + volume_types[type_id]] += size

    # prepare the output
    ptable = PrettyTable(["Project ID", "Resource", "Quota -> Real",
                         "Sync Status"])

    # find discrepancies between quota usage and real usage
    quota_usages_to_sync = {}
    for resource in resource_types:
        try:
            if real_usages[resource] != quota_usages[resource]:
                quota_usages_to_sync[resource] = real_usages[resource]
                ptable.add_row([args.project_id, resource,
                               str(quota_usages[resource]) + ' -> ' +
                               str(real_usages[resource]),
                               '\033[1m\033[91mMISMATCH\033[0m'])
            else:
                ptable.add_row([args.project_id, resource,
                               str(quota_usages[resource]) + ' -> ' +
                               str(real_usages[resource]),
                               '\033[1m\033[92mOK\033[0m'])
        except KeyError:
            pass

    if len(quota_usages):
        print ptable

    # sync the quota with the real usage
    if quota_usages_to_sync and not args.nosync and (args.sync or yn_choice()):
        sync_quota_usages_project(cinder_metadata, args.project_id,
                                  quota_usages_to_sync)


if __name__ == "__main__":
    main()
