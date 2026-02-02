from typing import List, Type

from sqlfluff.core.plugin import hookimpl
from sqlfluff.core.rules import BaseRule


@hookimpl
def get_rules() -> List[Type[BaseRule]]:
    from custom_rules.rules import Rule_DBO_LL11
    return [Rule_DBO_LL11]

