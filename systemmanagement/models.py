from django.db import models
from django_ltree_field.fields import LTreeField

# Create your models here.
class AllEquipment(models.Model):
    equipment_id = models.BigIntegerField(primary_key=True)
    equipment_path = LTreeField(unique=True)
    equipment_tree_level = models.IntegerField()
    equipment_sort_identifier = models.TextField()
    equipment_full_identifier = models.TextField()
    equipment_location_path = models.CharField(max_length=255)
    equipment_location_identifier = models.CharField(max_length=255)
    equipment_local_identifier = models.CharField(max_length=255)
    type_id = models.IntegerField()
    equipment_description = models.TextField()
    equipment_is_approved = models.BooleanField()
    equipment_comment = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'all_equipment'

class EquipmentType(models.Model):
    id = models.BigIntegerField(primary_key=True)
    path = LTreeField(unique=True)
    label = models.CharField(max_length=255)
    model = models.TextField()
    modifier = models.TextField()
    manufacturer = models.TextField()
    description = models.TextField()
    comment = models.TextField()
    is_approved = models.BooleanField()
    modified_at = models.DateTimeField()
    origin_path = LTreeField()
    class Meta:
        managed = False
        db_table = 'equipment_type'

class Resource(models.Model):
    id = models.BigIntegerField(primary_key=True)
    resource_group_id = models.BigIntegerField()
    modifier = models.TextField()
    description = models.TextField()
    comment = models.TextField()
    modified_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'resource'
class EquipmentResource(models.Model):
    equipment_id = models.BigIntegerField()
    equipment_path = LTreeField(unique=True)
    equipment_tree_level = models.IntegerField()
    equipment_sort_identifier = models.TextField()
    equipment_full_identifier = models.TextField()
    equipment_location_path = models.CharField(max_length=255)
    equipment_location_identifier = models.CharField(max_length=255)
    equipment_local_identifier = models.CharField(max_length=255)
    type_id = models.IntegerField()
    equipment_description = models.TextField()
    equipment_is_approved = models.BooleanField()
    equipment_comment = models.CharField(max_length=255)
    type_resource_id = models.BigIntegerField()
    type_path = models.CharField(max_length=255)
    definition_type_id = models.BigIntegerField()
    resource_id = models.BigIntegerField()
    type_resource_comment = models.TextField()

    class Meta:
        managed = False
        db_table = 'all_equipment_resource'

class AllConnection(models.Model):
    connection_id = models.BigIntegerField(primary_key=True)
    connection_path = LTreeField(unique=True)
    connection_tree_level = models.IntegerField()
    connection_identifier_location = models.TextField()
    connection_identifier = models.TextField()
    connection_local_identifier = models.CharField(max_length=255)
    connection_type_id = models.IntegerField()
    connection_type_description = models.TextField()
    connection_description = models.TextField()
    connection_length = models.FloatField()
    connection_is_approved = models.BooleanField()
    connection_comment = models.TextField()
    start_equipment_id = models.IntegerField()
    start_interface_id = models.IntegerField()
    start_interface_full_identifier = models.TextField()
    start_interface_description = models.TextField()
    end_equipment_id = models.IntegerField()
    end_interface_id = models.IntegerField()
    end_interface_full_identifier = models.TextField()
    end_interface_description = models.TextField()
    class Meta:
        managed = False
        db_table = 'all_connection_interface'

class ConnectionType(models.Model):
    id = models.BigIntegerField(primary_key=True)
    path = LTreeField(unique=True)
    label = models.CharField(max_length=255)
    model = models.TextField()
    modifier = models.TextField()
    manufacturer = models.TextField()
    description = models.TextField()
    comment = models.TextField()
    is_approved = models.BooleanField()
    modified_at = models.DateTimeField()
    class Meta:
        managed = False
        db_table = 'connection_type'

class PurchasingEquipmentType(models.Model):
    type_path = LTreeField(unique=True, primary_key=True)
    type_label = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    type_modifier = models.CharField(max_length=255)
    manufacturer = models.TextField()
    type_description = models.TextField()
    type_comment = models.TextField()
    type_is_approved = models.BooleanField()
    total_required = models.BigIntegerField()
    ordered_count = models.BigIntegerField()
    to_order_count = models.BigIntegerField()
    received_count = models.BigIntegerField()
    installed_count = models.BigIntegerField()
    lead_time_days = models.IntegerField()
    class Meta:
        managed = False
        db_table = 'type_purchasing'

class PurchasingConnectionType(models.Model):
    type_path = LTreeField(unique=True, primary_key=True)
    type_label = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    type_modifier = models.CharField(max_length=255)
    manufacturer = models.TextField()
    type_description = models.TextField()
    type_comment = models.TextField()
    type_is_approved = models.BooleanField()
    total_quantity = models.BigIntegerField()
    total_length = models.FloatField()
    ordered_count = models.BigIntegerField()
    ordered_length = models.FloatField()
    to_order_count = models.BigIntegerField()
    to_order_length = models.FloatField()
    received_count = models.BigIntegerField()
    installed_count = models.BigIntegerField()
    lead_time_days = models.IntegerField()
    class Meta:
        managed = False
        db_table = 'connection_type_purchasing'

class PurchasingEquipmentTypeDetail(models.Model):
    type_path = LTreeField(unique=True, primary_key=True)
    type_modifier = models.CharField(max_length=255)
    type_description = models.TextField()
    type_label = models.CharField(max_length=255)
    equipment_full_identifier = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    manufacturer = models.TextField()
    equipment_description = models.TextField()
    lead_time_days = models.IntegerField()
    quote_reference = models.TextField()
    purchase_order_date = models.DateField()
    purchase_order_reference = models.TextField()
    due_date = models.DateField()
    class Meta:
        managed = False
        db_table = 'equipment_purchasing_detail'

class PurchasingConnectionTypeDetail(models.Model):
    connection_type_path = LTreeField(unique=True, primary_key=True)
    connection_type_modifier = models.CharField(max_length=255)
    connection_type_description = models.TextField()
    connection_type_label = models.CharField(max_length=255)
    connection_location_identifier = models.CharField(max_length=255)
    connection_description = models.TextField()
    lead_time_days = models.IntegerField()
    quote_reference = models.TextField()
    purchase_order_date = models.DateField()
    purchase_order_reference = models.TextField()
    due_date = models.DateField()
    class Meta:
        managed = False
        db_table = 'connection_purchasing_detail'