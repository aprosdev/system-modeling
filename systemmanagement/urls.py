from django.urls import path
from . import views

urlpatterns = [
    path('', views.system, name='system'),
    path('system/purchasing_overview', views.system_purchasing_overview, name='system_purchasing_overview'),
    path('system/purchasing_detail', views.system_purchasing_detail, name='system_purchasing_detail'),
    path('system/delivery', views.system_delivery, name='system_delivery'),
    path('system/state', views.system_state, name='system_state'),
    path('equipment/', views.equipment, name='equipment'),
    path('connections/', views.connections, name='connections'),
    path('definitions/', views.definitions, name='definitions'),
    path('definitions/system_users', views.definitions_system_users, name='definitions_system_users'),
    path('definitions/equipment_types', views.definitions_equipment_types, name='definitions_equipment_types'),
    path('definitions/equipment_properties', views.definitions_equipment_properties, name='definitions_equipment_properties'),
    path('definitions/equipment_resources', views.definitions_equipment_resources, name='definitions_equipment_resources'),
    path('definitions/equipment_interfaces', views.definitions_equipment_interfaces, name='definitions_equipment_interfaces'),
    path('definitions/equipment_interface_classes', views.definitions_equipment_interface_classes, name='definitions_equipment_interface_classes'),
    path('definitions/connection_types', views.definitions_connection_types, name='definitions_connection_types'),
    path('definitions/target_systems', views.definitions_target_systems, name='definitions_target_systems'),
    path('definitions/possible_equipment_connection_states', views.definitions_possible_equipment_connection_states, name='definitions_possible_equipment_connection_states'),
    path(r'equipment/getEquipmentChildElements', views.get_equipment_child_elements, name="get_equipment_child_elements"),
    path(r'connections/getConnectionChildElements', views.get_connection_child_elements, name="get_connection_child_elements"),
    path(r'connections/updateConnectionDetail', views.update_connection_detail, name='update_connection_detail'),
    path(r'connections/addConnection', views.add_connection, name='add_connection'),
    path(r'connections/removeConnection', views.remove_connection, name='remove_connection'),
    path(r'equipment/getEquipmentDetailsTableData', views.get_equipmentdetail_tabledata, name='get_equipmentdetail_tabledata'),
    path(r'system/getConnectionTypePurchasingOverview', views.get_ConnectionType_purchasing_overview, name='get_ConnectionType_purchasing_overview'),
    path(r'system/getEquipmentTypePurchasingOverview', views.get_EquipmentType_purchasing_overview, name='get_EquipmentType_purchasing_overview'),
    path(r'system/getConnectionTypePurchasingDetail', views.get_ConnectionType_purchasing_detail, name='get_ConnectionType_purchasing_detail'),
    path(r'system/getEquipmentTypePurchasingDetail', views.get_EquipmentType_purchasing_detail, name='get_EquipmentType_purchasing_detail'),
    path(r'system/getEquipmentStateDetail', views.get_equipment_state_detail, name='get_equipment_state_detail'),
    path(r'system/getConnectionStateDetail', views.get_connection_state_detail, name='get_connection_state_detail'),
    path(r'equipment/updateEquipmentDetail', views.update_equipment_detail, name='update_equipment_detail'),
    path(r'equipment/addEquipment', views.add_equipment_detail, name='add_equipment_detail'),
    path(r'equipment/updateEquipmentPropertyValue', views.update_equipment_property_value, name='update_equipment_property_value'),
    path(r'equipment/removeEquipment', views.remove_equipment, name='remove_equipment'),
    path(r'definitions/getEquipmentTypesAttributes', views.getEquipmentTypesAttributes, name= 'get_equipment_types_attributes'),
    path(r'definitions/getEquipmentTypesInterface', views.getEquipmentTypesInterface, name='getEquipmentTypesInterface'),
    path(r'system/updateEquipmentTypePurchaseDetail', views.updateEquipmentTypePurchaseDetail, name= 'updateEquipmentTypePurchaseDetail'),
    path(r'system/updateConnectionTypePurchaseDetail', views.updateConnectionTypePurchaseDetail, name = 'updateConnectionTypePurchaseDetail'),
    path(r'system/updateEquipmentCommercialState', views.updateEquipmentCommercialState, name='getEquipmentCommercialState'),
    path(r'system/updateConnectionCommercialState', views.updateConnectionCommercialState, name='updateConnectionCommercialState'),
    path(r'definitions/updateSystemParameters', views.updateSystemParameters, name='updateSystemParameters'),
    path(r'definitions/addSystemParameters', views.addSystemParameters, name='addSystemParameters'),
    path(r'definitions/removeSystemParameters', views.removeSystemParameters, name='removeSystemParameters'),
    path(r'definitions/updateEquipmentTypeDetail', views.updateEquipmentTypeDetail, name='updateEquipmentTypeDetail'),
    path(r'definitions/addEquipmentType', views.addEquipmentType, name='addEquipmentType'),
    path(r'definitions/removeEquipmentType', views.removeEquipmentType, name='removeEquipmentType'),
    path(r'definitions/addEquipmentTypeResource', views.addEquipmentTypeResource, name='addEquipmentTypeResource'),
    path(r'definitions/removeEquipmentTypeResource', views.removeEquipmentTypeResource, name='removeEquipmentTypeResource'),
    path(r'definitions/addEquipmentTypeInterface', views.addEquipmentTypeInterface, name='addEquipmentTypeInterface'),
    path(r'definitions/removeEquipmentTypeInterface', views.removeEquipmentTypeInterface, name='removeEquipmentTypeInterface'),
    path(r'definitions/addResourceGroup', views.addResourceGroup, name='addResourceGroup'),
    path(r'definitions/updateResourceGroup', views.updateResourceGroup, name='updateResourceGroup'),
    path(r'definitions/removeResourceGroup', views.removeResourceGroup, name='removeResourceGroup'),
    path(r'definitions/updateReourceDetail', views.updateReourceDetail, name='updateReourceDetail'),
    path(r'definitions/removeResourceFromGroup', views.removeResourceFromGroup, name='removeResourceFromGroup'),
    path(r'definitions/updatePropertyDetail', views.updatePropertyDetail, name='updatePropertyDetail'),
    path(r'definitions/addEquipmentProperty', views.addEquipmentProperty, name='addEquipmentProperty'),
]