/**
 * <copyright>
 * </copyright>
 *
 * $Id$
 */
package net.sf.orcc.cache.impl;

import java.util.Map;

import net.sf.orcc.cache.Cache;
import net.sf.orcc.cache.CacheFactory;
import net.sf.orcc.cache.CacheManager;
import net.sf.orcc.cache.CachePackage;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.Type;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.impl.EFactoryImpl;
import org.eclipse.emf.ecore.plugin.EcorePlugin;

/**
 * <!-- begin-user-doc --> An implementation of the model <b>Factory</b>. <!--
 * end-user-doc -->
 * @generated
 */
public class CacheFactoryImpl extends EFactoryImpl implements CacheFactory {
	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @deprecated
	 * @generated
	 */
	@Deprecated
	public static CachePackage getPackage() {
		return CachePackage.eINSTANCE;
	}

	/**
	 * Creates the default factory implementation.
	 * <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * @generated
	 */
	public static CacheFactory init() {
		try {
			CacheFactory theCacheFactory = (CacheFactory)EPackage.Registry.INSTANCE.getEFactory("http://orcc.sf.net/cache"); 
			if (theCacheFactory != null) {
				return theCacheFactory;
			}
		}
		catch (Exception exception) {
			EcorePlugin.INSTANCE.log(exception);
		}
		return new CacheFactoryImpl();
	}

	/**
	 * Creates an instance of the factory.
	 * <!-- begin-user-doc --> <!--
	 * end-user-doc -->
	 * @generated
	 */
	public CacheFactoryImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EObject create(EClass eClass) {
		switch (eClass.getClassifierID()) {
			case CachePackage.CACHE: return createCache();
			case CachePackage.CACHE_MANAGER: return createCacheManager();
			case CachePackage.EOBJECT_TO_EXPRESSION_MAP_ENTRY: return (EObject)createEObjectToExpressionMapEntry();
			case CachePackage.EOBJECT_TO_EOBJECT_MAP_ENTRY: return (EObject)createEObjectToEObjectMapEntry();
			case CachePackage.EOBJECT_TO_TYPE_MAP_ENTRY: return (EObject)createEObjectToTypeMapEntry();
			default:
				throw new IllegalArgumentException("The class '" + eClass.getName() + "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public Cache createCache() {
		CacheImpl cache = new CacheImpl();
		return cache;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public CacheManager createCacheManager() {
		CacheManagerImpl cacheManager = new CacheManagerImpl();
		return cacheManager;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<EObject, Expression> createEObjectToExpressionMapEntry() {
		EObjectToExpressionMapEntryImpl eObjectToExpressionMapEntry = new EObjectToExpressionMapEntryImpl();
		return eObjectToExpressionMapEntry;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<EObject, EObject> createEObjectToEObjectMapEntry() {
		EObjectToEObjectMapEntryImpl eObjectToEObjectMapEntry = new EObjectToEObjectMapEntryImpl();
		return eObjectToEObjectMapEntry;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Map.Entry<EObject, Type> createEObjectToTypeMapEntry() {
		EObjectToTypeMapEntryImpl eObjectToTypeMapEntry = new EObjectToTypeMapEntryImpl();
		return eObjectToTypeMapEntry;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public CachePackage getCachePackage() {
		return (CachePackage)getEPackage();
	}

} // CacheFactoryImpl
