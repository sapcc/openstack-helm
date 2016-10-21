# Copyright 2015 OpenStack Foundation
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

"""Neutron routers in Cisco devices

Revision ID: 53f08de0523f
Revises: 2921fe565328
Create Date: 2015-09-28 09:10:46.191557

"""

# revision identifiers, used by Alembic.
revision = '53f08de0523f'
down_revision = 'ff1d905b4db'
depends_on = ('2921fe565328')

from alembic import op
import sqlalchemy as sa

from neutron.db import migration


def upgrade():
    op.create_table('cisco_router_types',
        sa.Column('tenant_id', sa.String(length=255), nullable=True),
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.Column('template_id', sa.String(length=36), nullable=True),
        sa.Column('ha_enabled_by_default', sa.Boolean(), nullable=False,
                  server_default=sa.sql.false()),
        sa.Column('shared', sa.Boolean(), nullable=False,
                  server_default=sa.sql.true()),
        sa.Column('slot_need', sa.Integer(), autoincrement=False,
                  nullable=True),
        sa.Column('scheduler', sa.String(length=255), nullable=False),
        sa.Column('driver', sa.String(length=255), nullable=False),
        sa.Column('cfg_agent_service_helper', sa.String(length=255),
                  nullable=False),
        sa.Column('cfg_agent_driver', sa.String(length=255), nullable=False),
        sa.ForeignKeyConstraint(['template_id'],
                                ['cisco_hosting_device_templates.id'],
                                ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    if migration.schema_has_table('cisco_router_mappings'):
        op.add_column('cisco_router_mappings',
                      sa.Column('role', sa.String(255), nullable=True))
        op.add_column('cisco_router_mappings',
                      sa.Column('router_type_id', sa.String(length=36),
                                nullable=False))
        op.create_foreign_key('cisco_router_mappings_ibfk_3',
                              source_table='cisco_router_mappings',
                              referent_table='cisco_router_types',
                              local_cols=['router_type_id'],
                              remote_cols=['id'])



        # ****** This foreign key is never present ********

        #op.drop_constraint('cisco_router_mappings_ibfk_2',
        #                   'cisco_router_mappings', type_='foreignkey')


        op.drop_constraint('cisco_router_mappings_pkey',
                           'cisco_router_mappings', type_='primary')

        # ****** End of Hack *****



        op.create_foreign_key('cisco_router_mappings_ibfk_2',
                              source_table='cisco_router_mappings',
                              referent_table='routers',
                              local_cols=['router_id'],
                              remote_cols=['id'],
                              ondelete='CASCADE')
        op.create_primary_key(
            constraint_name='pk_cisco_router_mappings',
            table_name='cisco_router_mappings',
            columns=['router_id', 'router_type_id'])
        op.add_column('cisco_router_mappings',
                      sa.Column('inflated_slot_need', sa.Integer(),
                                autoincrement=False, nullable=True,
                                server_default='0'))
        op.add_column('cisco_router_mappings',
                      sa.Column('share_hosting_device', sa.Boolean(),
                                nullable=False, server_default=sa.sql.true()))
        op.create_index(op.f('ix_cisco_router_types_tenant_id'),
                        'cisco_router_types', ['tenant_id'], unique=False)