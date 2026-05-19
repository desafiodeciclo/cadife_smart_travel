class Routes {
  const Routes._();

  static String proposalCreate(String leadId) => '/agency/proposals/$leadId/new';
  static String leadEdit(String leadId) => '/agency/leads/$leadId/edit';
}
