#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('Demo for Inheritance of Metaclass')
'''
Quotes:
https://stackoverflow.com/questions/34781840/using-new-to-override-init-in-subclass
https://stackoverflow.com/questions/36152062/how-can-i-use-multiple-inheritance-with-a-metaclass
https://stackoverflow.com/questions/70358379/inheritance-from-metaclasses-in-python
https://stackoverflow.com/questions/65539129/how-does-inheritance-work-in-python-metaclass

'''

class ParentMeta(type):
    def __new__(mcs, cls, bases, attrs, **kw):
        attrs['extra'] = mcs.extra
        newcls = super().__new__(mcs, cls, bases, attrs)
        user_init = newcls.__init__
        def __init__(self, *pos, **kw):
            print("ParentMeta __init__ called")
            user_init(self, *pos, **kw)
            self.extra()
        print("Replacing Parent __init__")
        setattr(newcls, '__init__', __init__)
        return newcls

    def extra(self):
        print("Extra called")

class Parent(metaclass = ParentMeta):

    def __init__(self):
        super().__init__()
        print("Parent __init__ called")

p = Parent()

#[1] A metaclass must inherit another metaclass
class ChildMeta(ParentMeta):
    def __new__(mcs, cls, bases, attrs, **kw):
        attrs['extraChild'] = mcs.extraChild
        newcls = super().__new__(mcs, cls, bases, attrs)
        user_init = newcls.__init__
        def __init__(self, *pos, **kw):
            print("ChildMeta __init__ called")
            user_init(self, *pos, **kw)
            self.extraChild()
        print("Replacing Child __init__")
        setattr(newcls, '__init__', __init__)
        return newcls

    def extraChild(self):
        print("Extra Child called")

#[1] If there are any bases to inherit, its metaclass must inherit all their metaclasses in chain
class Child(Parent, metaclass = ChildMeta):

    def __init__(self):
        super().__init__()
        print("Child __init__ called")

# Below print results are placed here
#>>> Replacing Parent __init__
#>>> Replacing Child __init__

c = Child()

# Below print results are placed here
#>>> ChildMeta __init__ called
#>>> ParentMeta __init__ called
#>>> ParentMeta __init__ called
#>>> Parent __init__ called
#>>> Extra called
#>>> Child __init__ called
#>>> Extra called
#>>> Extra Child called

'''
[COMPREHENSION]
[01] When defining <class Child...>, invoke <metaclass of current class>.__call__, which is <class ChildMeta>
[02] Since <ChildMeta.__call__> is to be invoked, <bases of ChildMeta>.__call__ are invoked ahead of it
[03] This chain leads to <class ParentMeta>, since ParentMeta.__call__ is not defined, ParentMeta.__new__ and ParentMeta.__init__
      are to be invoked in line as indicated by type.__call__
[04] That leads to the first print result <Replacing Parent __init__>; now Child.__init__ has become:
    def __init__(self):
        #From ParentMeta
        print("ParentMeta __init__ called")

        #From Child
        super().__init__()
        print("Child __init__ called")

        #From ParentMeta
        self.extra()
[05] Now the process returns to [02], which leads to <Replacing Child __init__>; now Child.__init__ has become:
    def __init__(self):
        #From ChildMeta
        print("ChildMeta __init__ called")

        #From ParentMeta
        print("ParentMeta __init__ called")

        #From Child
        super().__init__()
        print("Child __init__ called")

        #From ParentMeta
        self.extra()

        #From ChildMeta
        self.extraChild()
[06] Now the process comes to the inheritance of <Parent>, along with Parent.__call__; similar to above steps, Parent.__init__ becomes:
    def __init__(self):
        #From ParentMeta
        print("ParentMeta __init__ called")

        #From Parent
        super().__init__()
        print("Parent __init__ called")

        #From ParentMeta
        self.extra()
[07] Finally, Child.__init__ is constructed as below (literally):
    def __init__(self):
        #From ChildMeta
        print("ChildMeta __init__ called")

        #From ParentMeta
        print("ParentMeta __init__ called")

        #From Child
    #>>>Called Parent.__init__
        #From ParentMeta
        print("ParentMeta __init__ called")

        #From Parent
        super().__init__()              #Actually nothing happens here
        print("Parent __init__ called")

        #From ParentMeta
        self.extra()
    #<<<Called Parent.__init__
        print("Child __init__ called")

        #From ParentMeta
        self.extra()

        #From ChildMeta
        self.extraChild()
[08] Till now the definition stage <class Child...> is complete
[09] All constructors (i.e. both metaclasses) have been defined till now, hence <print> in their definitions are no longer executed
      during the instantiation of <Child>. E.g. <c = Child()> will directly call the method defined as [07], while the construction
      steps of [07] have been printed before and no longer be printed again, see line <#62> - <#64>
[10] The final printing result is clear now
[11] Try to exchange the line <#59> - <#60> and see the difference
'''
