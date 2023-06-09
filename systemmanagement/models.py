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
    equipment_type_id = models.BigIntegerField(primary_key=True)
    equipment_type_path = LTreeField(unique=True)
    equipment_type_label = models.CharField(max_length=255)
    equipment_type_model = models.TextField()
    equipment_type_modifier = models.TextField()
    equipment_type_manufacturer = models.TextField()
    equipment_type_description = models.TextField()
    equipment_type_comment = models.TextField()
    equipment_type_is_approved = models.BooleanField()
    equipment_type_modified_at = models.DateTimeField()
    equipment_type_origin_path = LTreeField()
    class Meta:
        managed = False
        db_table = 'equipment_type'