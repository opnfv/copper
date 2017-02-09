==============================================
OPNFV Danube Copper Overview
==============================================

.. contents::
   :depth: 3
   :local:

Introduction
------------

The `OPNFV Copper <https://wiki.opnfv.org/copper>`_ project aims to help ensure
that virtualized infrastructure and application deployments comply with goals of
the NFV service provider or the VNF designer/user.

This is the third ("Danube") release of the Copper project. The documentation
provided here focuses on the overall goals of the Copper project and the
specific features supported in the Colorado release.

Overall Goals for Configuration Policy
--------------------------------------

As focused on by Copper, configuration policy helps ensure that the NFV service
environment meets the requirements of the variety of stakeholders which will
provide or use NFV platforms.

These requirements can be expressed as an *intent* of the stakeholder,
in specific terms or more abstractly, but at the highest level they express:

  * what I want
  * what I don't want

Using road-based transportation as an analogy, some examples of this are shown
below:

.. list-table:: Configuration Intent Example
   :widths: 10 45 45
   :header-rows: 1

   * - Who I Am
     - What I Want
     - What I Don't Want
   * - user
     - a van, wheelchair-accessible, electric powered
     - someone driving off with my van
   * - road provider
     - keep drivers moving at an optimum safe speed
     - four-way stops
   * - public safety
     - shoulder warning strips, center media barriers
     - speeding, tractors on the freeway

According to their role, service providers may apply more specific configuration
requirements than users, since service providers are more likely to be managing
specific types of infrastructure capabilities.

Developers and users may also express their requirements more specifically,
based upon the type of application or how the user intends to use it.

For users, a high-level intent can be also translated into a more or less specific
configuration capability by the service provider, taking into consideration
aspects such as the type of application or its constraints.

Examples of such translation are:

.. list-table:: Intent Translation into Configuration Capability
   :widths: 40 60
   :header-rows: 1

   * - Intent
     - Configuration Capability
   * - network security
     - firewall, DPI, private subnets
   * - compute/storage security
     - vulnerability monitoring, resource access controls
   * - high availability
     - clustering, auto-scaling, anti-affinity, live migration
   * - disaster recovery
     - geo-diverse anti-affinity
   * - high compute/storage performance
     - clustering, affinity
   * - high network performance
     - data plane acceleration
   * - resource reclamation
     - low-usage monitoring

Although such intent-to-capability translation is conceptually useful, it is
unclear how it can address the variety of aspects that may affect the choice of
an applicable configuration capability.

For that reason, the Copper project will initially focus on more specific
configuration requirements as fulfilled by specific configuration capabilities,
as well as how those requirements and capabilities are expressed in VNF and service
design and packaging or as generic policies for the NFV Infrastructure.
