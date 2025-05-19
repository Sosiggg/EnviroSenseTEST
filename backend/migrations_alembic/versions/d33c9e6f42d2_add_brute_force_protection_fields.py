"""Add brute force protection fields

Revision ID: d33c9e6f42d2
Revises:
Create Date: 2025-05-20 03:01:15.351925

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd33c9e6f42d2'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to add brute force protection fields."""
    # Add failed_login_attempts column
    op.add_column('users', sa.Column('failed_login_attempts', sa.Integer(), nullable=True, server_default='0'))

    # Add last_failed_login column
    op.add_column('users', sa.Column('last_failed_login', sa.DateTime(), nullable=True))

    # Add account_locked_until column
    op.add_column('users', sa.Column('account_locked_until', sa.DateTime(), nullable=True))


def downgrade() -> None:
    """Downgrade schema by removing brute force protection fields."""
    # Remove account_locked_until column
    op.drop_column('users', 'account_locked_until')

    # Remove last_failed_login column
    op.drop_column('users', 'last_failed_login')

    # Remove failed_login_attempts column
    op.drop_column('users', 'failed_login_attempts')
