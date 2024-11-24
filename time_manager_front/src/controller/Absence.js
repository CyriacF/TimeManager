export const AbsenceType = Object.freeze({
  CP: 'Congés payés',
  CPSUP: 'Congés supplémentaire',
  CPSUPAPP: 'Congé supplémentaire apprenti',
  ABEventFamily: 'Absence événement familial',
  CParental: 'Congé parental',
  MAT: 'Maternité',
  PAT: 'Paternité',
  AcciTrav: 'Accident du travail',
  Maladie: 'Maladie',
  CSS: 'Congé sans solde',
  Travail: 'Travail',
  FER: 'Férié',
});

// Usage
console.log(AbsenceType.CP); // Output: 'Congés payés'